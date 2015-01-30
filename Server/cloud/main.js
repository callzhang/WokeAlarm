// getRelevantUsers
// parameters: objectId - user id,
//             topk - preferred number of user ids 
//             radius - search radius in kilometers(optional)
//
Parse.Cloud.define("getRelevantUsers", function(request, response) {
  var objectId = request.params.objectId;
  var radius = -1;
  if (request.params.radius !== undefined) radius = request.params.radius;
  var topk = request.params.topk;
  var userLocation = request.params.location;

  //runtime objects
  var userObject;
  var nearbyUsers;
  var friends;;
  var userGeoPoint

  //query using objectId
  var query = new Parse.Query(Parse.User);
  query.get(objectId).then(function (user) {
    userObject = user;
    userGeoPoint =  new Parse.GeoPoint({latitude: userLocation.latitude, longitude: userLocation.longitude});
    // Create a query for places
    var query = new Parse.Query(Parse.User);
    // Interested in locations near user.
    if (radius > 0 && radius < 6371)
      query.withinKilometers("location", userGeoPoint, radius);
    else
      query.near("location", userGeoPoint);
    query.ascending();
    // Limit what could be a lot of points.
    query.limit(2*topk);
    // Final list of objects
    return query.find();
  }).then(function (list) {
    nearbyUsers = list;
    var relation = userObject.relation("friends");
    return relation.query().find();
  }).then(function (list) {
    friends = list;
    friends.forEach(function (friend) {
      if (nearbyUsers.indexOf(friend) != -1){
        nearbyUsers.push(friend);
      }
    });
    //generate k users by gender
    var query = new Parse.Query(Parse.User);

    query.notEqualTo("gender", userObject.gender);
    query.limit(topk);
    return query.find();
  }).then(function (opGenderList) {
    opGenderList.forEach(function (user) {
      if (nearByUsers.indexOf(user) != -1){
        nearByUsers.push(user);
      }
    });

    //remove him/herself
    var mergedList = nearbyUsers.filter(function (x) { return x.id != userObject.id});

    //get distance
    var minDistance = 9999;
    var maxDistance = -1;
    mergedList.forEach(function (user) {
      var geoPoint = user.get("location");
      var distance = geoPoint.kilometersTo(userGeoPoint);
      //set distance for every user
      if (distance > maxDistance) maxDistance = distance;
      if (distance < minDistance) minDistance = distance;
      user.set("distance", distance);
    });

    //sort distance
    mergedList.forEach(function (user) {
      //distance score
      var base = maxDistance==minDistance ? 0.01:(maxDistance-minDistance);
      var locationScore = (user.get("distance") - minDistance)  / base;
      locationScore = Math.pow(locationScore - 1, 2);

      //gender score
      var genderScore = userObject.get("gender") == user.get("gender") ? 0 : 1;
      var friendScore = 0;
      if (friends.indexOf(user.id) != -1)
        friendScore = 1;

      //time score
      var timeScore = 0;
      var currentTime = new Date();//time in sec
        var otherCachedInfo = user.get("cachedInfo");
        if (otherCachedInfo != null) {
          var alarms = otherCachedInfo["alarm_schedule"];
          var nextAlarm = new Date(currentTime.getTime()+7*24*3600*1000);
          for(var wkd in alarms) {
            var time = alarms[wkd];
            var t = new Date(time);
            while (t < currentTime) {
              var t_ = t.getTime() + 7 * 24 * 3600 * 1000;
              t = new Date(t_);
            }
            if (t < nextAlarm) {
              nextAlarm = t;
            }
          }
          var timeDiff = Math.abs(nextAlarm - currentTime) / 600 / 1000;//10min
          timeScore = Math.pow(1.1, -timeDiff);
        }
      //console.log(locationScore + "|" + genderScore + "|" + friendScore + "|" + timeScore)
      user.set("score", locationScore + genderScore + friendScore + timeScore);
    });

    //sort
    mergedList.sort(function(x, y) {
      return y.get("score") - x.get("score")
    });
    //remove redundant
    while (mergedList.length > topk) {
      mergedList.pop();
    }
    //log
    var sampleN = 5;
    for (var i= 0; i<sampleN; i++){
      var j = Math.floor(mergedList.length / sampleN * i);
      var user = mergedList[j];
      console.log("Sample "+j+": ("+user.get("score")+")");
    }

    response.success(mergedList.map(function(x) { return x.id; }));

  });
});

//parameters:
//  senderID: objectId for sender
//  receiverID: objectId for receiver
Parse.Cloud.define("sendFriendRequestNotificationToUser", function(request, response) {
  Parse.Cloud.useMasterKey();
  var senderID = request.params.sender;
  var receiverID = request.params.receiver;

  var querySender = new Parse.Query(Parse.User);
  querySender.equalTo("objectId", senderID);
  querySender.first({
    success: function(sender) {

    var query = new Parse.Query(Parse.User);
    query.equalTo("objectId", receiverID);
    var user = null;
    query.first({
      success: function(receiver) {
          console.log(sender.get("name")  + " requesting friendship" + receiver.get("name"));

          //create a notification object
          //TODO: check sender/owner exists or not 
          var notification = new Parse.Object.extend("EWNotification");
          notification.set("importance", 0);
          notification.set("sender", senderID);
          notification.set("receiver", receiverID);
          notification.set("owner", receiver);
          notification.set("type", "friendship_request");
          notification.set("userInfo",  {User:senderID, owner:receiverID, type: "notice", sendername: sender.get("firstName") });

          //console.log(notification);
          //save notification
          notification.save(null, {
            success: function(notification) {
              console.log(notification.id + " saved");
              var relation = receiver.relation("notifications");
              relation.add(notification);
              receiver.save(null, {
                success: function(receiver) {

                  //push message to the owner. 
                  var query = new Parse.Query(Parse.Installation);
                  query.equalTo('userId', receiver.id);

                    Parse.Push.send({
                      where: query, // Set our Installation query
                      data: {
                        alert: "Friendship request",
                        title: "Friendship request",
                        body: sender.get("name") + " is requesting your premission to become your friend.",
                        userInfo: "{User:" + senderID + ", type:friendship_request}",
                        type: "notice",
                        notificationID: notification.id
                      }
                      }, {
                      success: function() {
                        // Push was successful
                        notification.fetch().then(function(){
                          response.success(notification);
                        })
                      },
                      error: function(error) {
                        // Handle error
                        response.error("error: " + error.message);
                      }
                    });
                },
                error: function(receiver, error) {
                  response.error("failed to save receiver: " + error.message);
                }
              });

              
            },
            error: function(notification, error) {
              console.log("save notification object failed");
              console.log(error.message);
              response.error("create Notification object failed");
            }
          });
      },
      error: function() {
        console.log("cannot find owner");
        response.error("cannot find owner");
      }
    });

    },
    error: function() {
      console.log("cannot find owner");
      response.error("cannot find owner");
    }
  });
});

Parse.Cloud.define("sendFriendAcceptNotificationToUser", function(request, response) {
  Parse.Cloud.useMasterKey();
  var sender = request.params.sender;

  var querySender = new Parse.Query(Parse.User);
  querySender.equalTo("objectId", sender);
  querySender.first({
    success: function(senderObject) {

    var owner = request.params.owner;
    var query = new Parse.Query(Parse.User);
    query.equalTo("objectId", owner);
    var user = null;
    query.first({
      success: function(ownerObject) {
          console.log(senderObject.get("name") + " " + ownerObject.get("name"));

          //create a notification object
          //TODO: check sender/owner exists or not 
          var notification = new Parse.Object.extend("EWNotification");
          notification.set("importance", 0);
          notification.set("sender", sender);
          notification.set("owner", ownerObject);
          notification.set("type", "friendship_accepted");
          notification.set("userInfo",  {User:sender, owner:owner, type: "notice", sendername: senderObject.get("name") });

          //console.log(notification);
          //save notification
          notification.save(null, {
            success: function(notification) {
              console.log(notification.id + " saved");
              var relation = ownerObject.relation("notifications");
              relation.add(notification);
              ownerObject.save(null, {
                success: function(ownerObject) {

                  //push message to the owner. 
                  var query = new Parse.Query(Parse.Installation);
                  //query.equalTo('username', ownerObject.get("username"));
                  query.equalTo('userId', ownerObject.id);

                  var gender = "this person";
                  if (senderObject.get("gender") === "male") gender = "him";
                  if (senderObject.get("gender") === "female") gender = "her";

                  Parse.Push.send({
                    where: query, // Set our Installation query
                    data: {
                      alert: "Friendship accepted",
                      title: "Friendship accepted",
                      body: senderObject.get("name") + " has approved your friendship request. Now send " + gender + " a voice greeting!",
                      type: "notice",
                      userInfo: "{User:" + sender + ", type:friendship_accepted}",
                      notificationID: notification.id

                    }
                    }, {
                    success: function() {
                      // Push was successful
                      response.success("done");
                    },
                    error: function(error) {
                      // Handle error
                      console.log("push error: " + error.message);
                      response.error("error: " + error.message);
                    }
                  });

                },
                error: function(ownerObject, error) {
                  response.error("failed to save ownerObject: " + error.message);
                }
              });

              
            },
            error: function(notification, error) {
              console.log("save notification object failed");
              response.error("create Notification object failed");
            }
          });
      },
      error: function() {
        console.log("cannot find owner");
        response.error("cannot find owner");
      }
    });

    },
    error: function() {
      console.log("cannot find owner");
      response.error("cannot find owner");
    }
  });
});


Parse.Cloud.define("getWokeVoice", function(request, response) {
  var currentUserId = request.params.userId;
  var query = new Parse.Query(Parse.User);
  query.get(currentUserId, {
    success: function (user) {
      console.log("Current user: " + user.get("name"));
      var query = new Parse.Query(Parse.User);
      query.equalTo("username", "woke");
      query.first({
        success: function (woke) {
          console.log("Found woke: "+ woke.id);
          //create a media
          var EWMedia = Parse.Object.extend("EWMedia");
          var media = new EWMedia;
          media.set("receiver", user);
          media.set("author", woke);
          media.set("message", "Voice from Woke");
          media.set("type", "voice");
          //get voice
          var voiceFile = Parse.Object.extend("EWMediaFile");
          var mediaFileQuery = new Parse.Query(voiceFile);
          mediaFileQuery.equalTo("owner", woke.id);
          mediaFileQuery.find({
            success: function (voices) {
              console.log("Get Woke voices: "+voices.length);
              var n = Math.floor(Math.random() * voices.length);
              console.log("Random voice chosen: "+n);
              voiceFile = voices[n];
              media.set("mediaFile", voiceFile);

              //save
              media.save().then(function(media){
                //save file->medias relation
                var mediasRelation = voiceFile.relation("medias");
                mediasRelation.add(media);
                voiceFile.save();
                //add woke->sentMedias relation
                var sentMedias = woke.relation("sentMedias");
                sentMedias.add(media);
                woke.save();
                //add user->unreadMedia relation
                user.add("unreadMedias", media);
                user.save();
              }, function(error){
                console.log("Relation mediaFile->media failed: "+error.message);
              });

              //send a push
              var query = new Parse.Query(Parse.Installation);
              query.equalTo('userId', currentUserId);

              Parse.Push.send({
                where: query,
                data: {
                  alert: "You got a new media",
                  title: "You got a new media",
                  body: "Woke send you a new media.",
                  type: "media",
                  media_type: "media",
                  media: media.id
                }
              }, {
                success: function () {
                  // Push was successful
                  response.success(media.id);
                  console.log("Woke voice (" +media.id +") created and push sent");
                },
                error: function (error) {
                  // Handle error
                  console.error("Failed to send push");
                  console.log("Failed to send push for test media: "+error.message);
                }
              });
            }, error: function (list, error) {
              console.log("cannot find woke voices");
              response.error("Cannot find woke voices: ", + error.message);
            }
          });
        }, error: function (list, error) {
          console.log("failed to find Woke: " + error.message);
        }
      });
    },
    error: function (error) {
      console.log("Failed to find current user: ", error.message);
    }
  })
});

Parse.Cloud.define("syncUser", function(request, response) {
  Parse.Cloud.useMasterKey();
  //define the return object
  var info = {};

  //placeholder for deletion
  var objectsToDelete = {};

  //find the user
  var userInfo = request.params.user;
  var userID;
  var userUpdatedAt;
  for (var ID in userInfo){
    userID = ID;
    userUpdatedAt = userInfo[ID];
    console.log("Request for user "+userID+" with udpatedAt: "+userUpdatedAt);
  }
  var query = new Parse.Query(Parse.User);
  query.get(userID).then( function(user){

    //========== FUNCTIONS DEFINITION =============

    //process list function
    var processPOListForRelation = function(list, relationName){
      if (!list) list = [];
      console.log("===>Parsing "+list.length+" objects in relation "+relationName);

      //dict is {ID: updatedAt} pair
      var dict = request.params[relationName];

      var objectsNeedUpdate = [];
      list.forEach(function(PO){

        if (dict.hasOwnProperty(PO.id)) {
          //exists, compare date
          var clientUpdatedAt = dict[PO.id];
          if (PO.updatedAt - clientUpdatedAt > 5000){
            objectsNeedUpdate.push(PO);
            console.log("~Update object "+PO.id+" in relation "+relationName);
          }
          //delete after compare
          delete dict[PO.id];

        }else{
          //do not exists, add
          objectsNeedUpdate.push(PO);
          console.log("+New object "+PO.id+" in relation "+relationName);
        }
      });
      for (var objectId in dict){
        console.log("-Delete objects: "+ objectId  + " for relation: "+relationName);
        objectsToDelete[objectId] = relationName;
      }

      //assign updates to response
      if(objectsNeedUpdate.length > 0){
        info[relationName] = objectsNeedUpdate;
      }
    };

    //process single PO function
    var updatePOForRelation = function(PO, relationName){
      console.log("===>Parsing too-one relation "+relationName);

      //dict is {ID: updatedAt} pair
      var dict = request.params[relationName];
      if (PO){
        var clientUpdatedAt = dict[PO.id];
        if (clientUpdatedAt){
          //object exists in local, compare date
          if (PO.updatedAt - clientUpdatedAt > 5000){
            info[relationName] = PO;
            console.log("~Updated object: "+PO.id+ " for relation "+relationName);
          }
          delete dict[PO.id];
        }else {
          //object do not exist, add PO to response and add objectID to delete dic
          info[relationName] = PO;
          console.log("+New object: "+PO.id+ " for relation "+relationName);
        }
      }

      for (var ID in dict){
        console.log("-Delete objects: "+ ID  + " for relation: "+relationName);
        objectsToDelete[ID] = relationName;
      }
    };

    //=========== END OF FUNCTIONS =============

    //create an array of promise
    var promises = [];

    //add user
    console.log("Get user "+user.get("firstName")+" for syncing");
    if (user.updatedAt - userUpdatedAt > 10000) {
      var saveMe = function () {
        return user.fetch().then(function () {
          info["user"] = user;
        });
      };
      promises.push(saveMe());
    }else{
      //client user is newer, return
      response.success({});
    }

    //enumerate through keys
    for (var key in request.params){
      if (key == "user") continue;

      //socialGraph is the only to-one relation
      //we currently don't have a way to distinguish PFRelation or
      if (key == "socialGraph"){
        //toOne relation
        var PO = user.get(key);

        var toOnePromise = function (PO, relationName) {
          if(PO){
            return PO.fetch().then(function () {
              updatePOForRelation(PO, relationName);
            })
          }else{
            return Parse.Promise.as().then(function () {
              updatePOForRelation(PO, relationName);
            });
          }
        }
        promises.push(toOnePromise(PO, key));

      }else if(key == "unreadMedias") {
        //Relation is Array of POs
        var objects = user.get(key);
        var arrayPromise = function (objects, relationName) {
          var fetchAllPromise = Parse.Promise.as();
          if (objects) {
            objects.forEach(function(object){
              fetchAllPromise = fetchAllPromise.then(function () {
                return object.fetch();
              });
            });
          }

          fetchAllPromise = fetchAllPromise.then(function () {
            processPOListForRelation(objects, relationName);
          }, function(error){
            console.log("***Failed to fetch array for relation "+relationName+" with error: "+error.message);
          });

          return fetchAllPromise;
        }
        promises.push(arrayPromise(objects, key));


      }else {
         //To-Many Relation
         //create promise to work on to-many relation and add it to the 'When()' collection
        var toManyRelationPromise = function (relationName){
          var relation = user.relation(relationName);
          return relation.query().find().then(function (list) {
            processPOListForRelation(list, relationName);
          }, function(error){
            console.log("failed to get result for relation: "+relationName+" with error: "+error);
          })
        };
        promises.push(toManyRelationPromise(key));
      }
    }

    //wait until all promises finish
    return Parse.Promise.when(promises);


  }).then(function(){
    //add the delete queue to response
    console.log("Object to delete: "+ objectsToDelete.length);
    info["delete"] = objectsToDelete;
    //return
    response.success(info);
  }, function(error){
    console.log("Failed to run parallel inspection. "+error.message);
  });

});

Parse.Cloud.define("updateRelation", function(request, response) {
  Parse.Cloud.useMasterKey();
  var target = request.params.target;
  var related = request.params.related;
  var relationName = request.params.relation;
  var operation = request.params.operation;

  var update = function () {
    if (operation == "add"){
      //add to relation
      return target.fetch().then(function(){
        var relation = target.relation(relationName);
        relation.add(related);
        return target.save();
      }).then(function () {
        return target.fetch();
      });
    }
    else if(operation == "remove"){
      //remove from relation
      return target.fetch().then(function(){
        var relation = target.relation(relationName);
        relation.remove(related);
        target.save();
      }).then(function () {
        response.success(target);
      });
    }
    else if(operation == "delete"){
      //delete from to-one relation
      return target.fetch().then(function(){
        target.unset(relationName);
        target.save();
      }).then(function () {
        return target.fetch();
      });
    }
    else if(operation == "set"){
      //set to-one relation
      return target.fetch().then(function(){
        target.set(relationName, related);
        target.save();
      }).then(function () {
        return target.fetch();
      });
    }
    else if(operation == "append"){
      //add object array
      return target.fetch().then(function(){
        var array = target.get(relationName);
        if (!array){
          array = [];
        }
        array.push(related);
        target.set(relationName, array);
        target.save();
      }).then(function () {
        return target.fetch();
      }).then(function () {
        response.success(target);
      }, function(error){
        response.error(error.message);
      });
    }
    else if(operation == "pop"){
      //pop from object array
      return target.fetch().then(function(){
        var array = target.get(relationName);
        var newArr = [];
        array.forEach(function(obj){
          if(obj.id != related.id){
            newArr.push(obj);
          }
        });
        target.set(relationName, newArr);
        return target.save();
      });
    }
  };

  update().then(function () {
    return target.fetch();
  }).then(function () {
    response.success(target);
  }, function(error){
    response.error(error.message);
  });

});

Parse.Cloud.define("handleNewUser", function(request, response) {
  var userID = request.params.userID;
  var email = request.params.email;
  var facebookID = request.params.facebookID;

  //query against all EWSocial's stored info, detect existing relation
  var newUser;
  var query = new Parse.Query(Parse.User);
  var relatedUsers;
  query.get(userID).then( function(user){
    newUser = user;
    //query email in addressBook
    var EWSocial = Parse.Object.extend("EWSocial");
    var contactsQuery = new Parse.Query(EWSocial);
    contactsQuery.equalTo("addressBookFriends", email);
    return contactsQuery.find();
  }).then(function (users) {
    console.log("Found "+users.count+" users have email connection");
    //save users list
    relatedUsers = users;
    //query email in facebook
    var EWSocial = Parse.Object.extend("EWSocial")
    var facebookQuery = new Parse.Query(EWSocial);
    facebookQuery.equalTo("facebookFriends", facebookID);
    return facebookQuery.find();
  }).then(function (fbUsers) {
    console.log("Found "+fbUsers.lenth+" users have facebook connection");
    //add fb users
    fbUsers.forEach(function (fbUser) {
      relatedUsers.push(fbUser);
    });
    //send notification and EWNotification
    var notifications = [];
    relatedUsers.forEach(function (user) {

      var notification = new Parse.Object.extend("EWNotification");
      notification.set("importance", 0);
      notification.set("sender", userID);
      notification.set("receiver", user.id);
      notification.set("owner", user);
      notification.set("type", "new_user");
      notification.set("userInfo",  {User:userID, owner:user.id, type: "notice", sendername: newUser.get("firstName") });
      notifications.push(notification);
    });
    console.log("Saving "+notifications.length+"notifications");
    return Parse.Object.saveAll(notifications);
  }).then(function(notifications){
    var users = [];
    notifications.forEach(function (notification) {
      //save users
      var user = notification.get("owner");
      var notificationRelation = user.Relation('notifications');
      notificationRelation.add(notification);
      users.push(user);

      //send push notifications
      var pushQuery = new Parse.Query(Parse.Installation);
      query.equalTo('objectId', user.id);
      Parse.push.send({
        where: pushQuery,
        data: {
          alert: "Your friend " + newUser.get("firstName") + " " + newUser.get("lastName") + " just joined Woke!",
          title: "You have new friend joined!",
          body: "Your friend " + newUser.get("firstName") + " " + newUser.get("lastName") + " just joined Woke!",
          type: "notice",
          userInfo: "{User:" + newUser.id + ", type: new_user}",
          notificationID: notification.id
        }
      }, {
        success: function () {
          console.log("New user push sent to ", user.id);
        },
        error: function (error) {
          // Handle error
          console.log("push error: " + error.message);
          response.error("error: " + error.message);
        }
      });
    });
    return Parse.Object.saveAll(users);
  }).then(function (users) {
    response.success(users);
  }, function (error) {
    console.log("failed to save all users")
    response.error(error);
  })
});






//=================Background Job==================
Parse.Cloud.job("backgroundJob", function(request, status) {
  // Set up to modify user data
  Parse.Cloud.useMasterKey();
  // Query for all users
  var query = new Parse.Query(Parse.User);
  query.each(function(user) {
    //check last used time
    var lastTime = user.updatedAt;
    //console.log("last time: "+ lastTime + " for " + user.get("name"));
    var today = new Date();
    var oneDay = 24*60*60*1000;
    var diffDays = Math.abs((today.getTime() - lastTime.getTime())/(oneDay));
    console.log("diffDays: " + diffDays);

    if (diffDays >= 3) {

      // var notification = new Parse.Object.extend("EWNotification");
      // notification.set("importance", 0);
      // notification.set("sender", user.id);
      // notification.set("owner", user);
      // notification.set("type", "notice");
      // notification.set("userInfo",  {title:"Hello", body:"It has been a while since your last used Woke. Come to see what's new.", type: "notice", link:"Test"});
      

      //push message to the owner. 
      var query = new Parse.Query(Parse.Installation);
      query.equalTo('username', user.get("username"));
      Parse.Push.send({
        where: query, // Set our Installation query
        data: {
          alert: "Hello",
          title: "Hello From Woke",
          body: "It has been a while since your last used Woke. Come to see what's new.",
          type: "notice",
          userInfo: "{User:" + user + ", type:notice}"
        }
      }, {
        success: function() {
          // Push was successful
          console.log("Sent a reminder notice to user: " + user.username);

        },
        error: function(error) {
          // Handle error
          console.log("Failed to send a reminder notice: " + error.message);
        }
      });
    }

      
      // notification.save(null, {
      //       success: function(notification) {
      //         console.log(notification.id + " saved");
      //         var relation = user.relation("notifications");
      //         relation.add(notification);
      //         user.save(null, {
      //           success: function(user) {

      //             //push message to the owner. 
      //             var query = new Parse.Query(Parse.Installation);
      //             query.equalTo('username', user.get("username"));
 
      //               Parse.Push.send({
      //                 where: query, // Set our Installation query
      //                 data: {
      //                   alert: "test push",
      //                   title: "test push",
      //                   body: "annoying test!",
      //                   type: "notice",
      //                   userInfo: "{User:" + user + ", type:notice}",
      //                   notificationID: notification.id

      //                 }
      //                 }, {
      //                 success: function() {
      //                   // Push was successful
      //                   console.log("done");

      //                 },
      //                 error: function(error) {
      //                   // Handle error
      //                   console.log("error: " + error.message);
      //                 }
      //               });
                  

      //           },
      //           error: function(ownerObject, error) {
      //             response.error("failed to save ownerObject: " + error.message);
      //           }
      //         });

              
      //       },
      //       error: function(notification, error) {
      //         console.log("save notification object failed");
      //       }
      //     });

  }).then(function() {
    // Set the job's success status
    status.success("scanned for pushing notifications");
  }, function(error) {
    // Set the job's error status
    status.error("oops, sth is wrong: " + error.message);
  });
});