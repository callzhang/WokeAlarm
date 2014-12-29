// findWokeFriendsFromAddressBook
// parameters: contacts - contacts
Parse.Cloud.define("findUsersWithEmails", function (request, response) {
  var contacts = request.params.contacts;
  var query = new Parse.Query(Parse.User);
  query.containedIn("email", contacts);
  query.find({
    success: function (result) {
      response.success(result)
    },
    error: function () {
      response.error("Lookup Address Book Failed");
    }
  });
})


// getRelevantUsers 
// parameters: objectId - user id,
//             topk - preferred number of user ids 
//             radius - search radius in kilometers(optional)
// TODO: 
//       1. get task for calculating task score
Parse.Cloud.define("getRelevantUsers", function(request, response) {
  var objectId = request.params.objectId;
  var radius = -1;
  if (request.params.raius === undefined)
    radius = request.params.radius;
  var topk = request.params.topk;
  var userLocation = request.params.location;
  //console.log(radius);

  //query using objectId
  var query = new Parse.Query(Parse.User);
  query.equalTo("objectId", objectId);
  var user = null;
  query.first({
    success: function(result) {

      //response.success(results[0]);
      //user = results[0];
      var userObject = result;
      // User's location
      //var userGeoPoint = userObject.get("location");
      var userGeoPoint =  new Parse.GeoPoint({latitude: userLocation.latitude, longitude: userLocation.longitude});
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
      query.find({
        success: function(nearbyUsers) {
          //var relation = userObject.relation("friends");
          console.log(userObject);
          var friendsList = userObject.get("friends") === undefined ? [] 
                                                                    : userObject.get("friends").map(
                                                                        function(x) { 
                                                                          if (x===undefined) return "";
                                                                          return x.id; });
          console.log("friends:" +friendsList);
          var queryFriends = new Parse.Query(Parse.User);
          queryFriends.containedIn("objectId", friendsList);
          queryFriends.find({success: function(list) {
            //a list of friends
            //var friendsList = list.map(function(x) { return x.id; });

            for (i = 0; i < list.length; i++) {
              var hit = false;
              for (j = 0; j < nearbyUsers; j++) {
                if (nearbyUsers[j].id === list[i].id)
                  hit = true;
              }
              if (hit) nearbyUsers.push(list[i]);
            }

            //generate k users by gender
            var query = new Parse.Query(Parse.User);

            query.notEqualTo("gender", userObject.gender);  
            query.limit(topk);
            query.find({
              success: function(list) {
                for (i = 0; i < list.length; i++) {
                  var hit = false;
                  for (j = 0; j < nearbyUsers; j++) {
                    if (nearbyUsers[j].id != list[i].id)
                      hit = true;
                  }
                  if (hit) nearbyUsers.push(list[i]);
                }
                
                //remove him/herself
                var mergedList = nearbyUsers.filter(function (x) { return x.id != userObject.id});
                var minDistance = 9999;
                var maxDistance = -1;
                //var myGeoPoint = (userObject.get("location"));

                for (i = 0; i < mergedList.length; i++) {
                  var geoPoint = (mergedList[i].get("location"));

                  var distance = geoPoint.kilometersTo(userGeoPoint);
                  //set distance for every user
                  mergedList[i].set("distance", distance);
                  //console.log(distance);
                  if (distance > maxDistance) maxDistance = distance;
                  if (distance < minDistance) minDistance = distance;
                }

                //make ranking
                // var myCachedInfo = userObject.get("cachedInfo");
                // var mytime = null;

                // //console.log(myCachedInfo);
                // if (myCachedInfo != null) {
                //   var test = myCachedInfo.next_task_time;
                //   mytime = test;
                //   console.log(mytime);
                // }

                for (i = 0; i < mergedList.length; i++) {
                  var distance = mergedList[i].get("distance");
                  var locationScore = 1;
                  if (maxDistance - minDistance > 0.0001) {
                    locationScore = (distance - minDistance) * 2 / (maxDistance - minDistance);
                    locationScore = (locationScore - 1)^2;
                  }
                  var genderScore = 1;
                  if (userObject.gender === mergedList[i].gender) 
                    genderScore = 0;
                  var friendScore = 0;
                  if (friendsList.indexOf(mergedList[i].id) != -1)
                    friendScore = 1;
                  var taskScore = 0;

                  //time in sec
                  var currentTime = new Date().getTime() / 1000
                  if (currentTime != null) {
                    var otherCachedInfo = mergedList[i].get("cachedInfo");
                    if (otherCachedInfo != null) {
                      var otherTime = otherCachedInfo.next_task_time;
                      //console.log(otherTime + " " + mytime);
                      var timeDiff = Math.abs(otherTime - currentTime) / 60000 / 10;//10min
                      //console.log("time diff: " + timeDiff);
                      taskScore = Math.pow(1.1, -timeDiff);
                    }
                  }
  
                  //TODO: query task and compare with current user's alarm
                  mergedList[i].score = locationScore + genderScore + friendScore + taskScore;
                }

                mergedList.sort(function(x, y) {
                                   if (x.score < y.score) return -1;
                                   if (x.score > y.score) return 1;
                                   return 0; } );

                while (mergedList.length > topk) {
                  mergedList.pop();
                }

                response.success(mergedList.map(function(x) { return x.id; }));

              }
            });
          }
          });
        },
        error: function(error) {
          response.error("Can't find any user with criteria: "+error.message);
          console.log("search nearby users failed: " + error.message);
        }
      });
    },
    error: function() {
      response.error("user lookup failed");
    }
  });
});

//parameters:
//  sender: objectId for sender
//  owner: objectId for receiver
Parse.Cloud.define("sendFriendRequestNotificationToUser", function(request, response) {
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
          console.log(senderObject.get("name")  + " " + ownerObject.get("name"));

          //create a notification object
          //TODO: check sender/owner exists or not 
          var notification = new Parse.Object("EWNotification");
          notification.set("importance", 0);
          notification.set("sender", sender);
          notification.set("owner", ownerObject);
          //notification.set("receiver", owner);
          notification.set("type", "friendship_request");
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
                  query.equalTo('username', ownerObject.get("username"));

                    Parse.Push.send({
                      where: query, // Set our Installation query
                      data: {
                        alert: "Friendship request",
                        title: "Friendship request",
                        body: senderObject.get("name") + " is requesting your premission to become your friend.",
                        userInfo: "{User:" + sender + ", type:friendship_request}",
                        type: "notice",
                        notificationID: notification.id
                      }
                      }, {
                      success: function() {
                        // Push was successful
                        response.success("done");
                      },
                      error: function(error) {
                        // Handle error
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
          var notification = new Parse.Object("EWNotification");
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


Parse.Cloud.define("testSendWakeUpVoice", function(request, response) {
  var currentUserId = request.params.objectId;
  var query = new Parse.Query(Parse.User);
  query.get(currentUserId, {
    success: function (user) {
      //var user = Parse.User.current();
      console.log("Current user: " + user.get("name"));
      var query = new Parse.Query(Parse.User);
      query.equalTo("username", "woke");
      query.first({
        success: function (woke) {
          console.log("Found woke: "+ woke.id);
          //create a meida
          var EWMedia = Parse.Object.extend("EWMedia");
          var media = new EWMedia;
          media.set("receiver", user);
          media.set("author", woke);
          //TODO: assign activity
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

              //save file->medias relation
              media.save().then(function(media){
                var mediasRelation = voiceFile.relation("medias");
                mediasRelation.add(media);
                voiceFile.save();
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
                  media: media.get("objectId")
                }
              }, {
                success: function () {
                  // Push was successful
                  response.success("Push sent");
                  console.log("Test media Sent");
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

      // var notification = new Parse.Object("EWNotification");
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
          userInfo: "{User:" + user + ", type:notice}",
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
