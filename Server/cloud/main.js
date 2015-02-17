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
Parse.Cloud.define("sendFriendshipRequestToUser", function(request, response) {
  Parse.Cloud.useMasterKey();
  var senderID = request.params.sender;
  var receiverID = request.params.receiver;
  var sender;
  var receiver;
  var request;
  var notification;

  var EWFriendRequest = Parse.Object.extend("EWFriendRequest");

  var querySender = new Parse.Query(Parse.User);
  querySender.get(receiverID).then(function (object) {
    receiver = object;
    var querySender = new Parse.Query(Parse.User);
    return querySender.get(senderID);
  }).then(function (object) {
    sender = object;
    console.log(sender.get("firstName")  + " requesting friendship " + receiver.get("firstName"));
    //find request first
    var queryRequest = new Parse.Query(EWFriendRequest);
    queryRequest.equalTo("receiver", receiver);
    queryRequest.equalTo("sender", sender);
    return queryRequest.find();
  }).then(function (array) {
    if (array.length>0) {
      request = array[0];
      console.log("existing request find: "+request.id);
      var status = request.get("status");
      if (status == "friend_request_pending") {
        //finished
        console.log("request from "+senderID+" to "+receiverID+" already sent");
        response.success(request);
      } else if (status == "friend_request_friended") {
        //already friended
        console.log("request from "+senderID+" to "+receiverID+" already friended");
        response.success(request);
      } else {
        console.log("request from "+senderID+" to "+receiverID+" already denied");
        response.success(request);
      }
    }

    //find the opposite request
    var queryRequest = new Parse.Query(EWFriendRequest);
    queryRequest.equalTo("receiver", sender);
    queryRequest.equalTo("sender", receiver);
    return queryRequest.find();

  }).then(function (array) {
    if (array.length > 0) {
      request = array[0];
      console.log("existing opposite request from receiver find: "+request.id);
      var status = request.get("status");
      if (status == "friend_request_pending") {
        //finished
        console.log("request from "+receiverID+" to "+senderID+" already pending, accept now!");
        request.set("status", "friend_request_friended");
        request.save().then(function () {
          response.success(request)
        });
      } else if (status == "friend_request_friended") {
        //already friended
        console.log("request from "+receiverID+" to "+senderID+" already friended");
        response.success(request);
      } else {
        console.log("request from "+receiverID+" to "+senderID+" already denied");
        response.success(request);
      }
    }

    //create EWFriendRequest
    var EWFriendRequest = Parse.Object.extend("EWFriendRequest");
    request = new EWFriendRequest();
    request.set("receiver", receiver);
    request.set("sender", sender);
    request.set("status", "friend_request_pending");
    return request.save();

  }).then(function (object) {
    request = object;
    console.log("request saved");
    //create notification
    var EWNotification = Parse.Object.extend("EWNotification");
    notification = new EWNotification();
    notification.set("importance", 0);
    notification.set("sender", senderID);
    notification.set("receiver", receiverID);
    notification.set("owner", receiver);
    notification.set("type", "friendship_request");
    notification.set("friendRequestID", request.id);
    notification.set("userInfo",  {User:senderID, owner:receiverID, type: "notice", sendername: sender.get("firstName") });
    return notification.save();

  }).then(function (notification) {
    console.log("notification saved");

    //set request to users
    var promises = [];
    var friendshipRequestReceivedRelation = sender.relation("friendshipRequestReceived");
    friendshipRequestReceivedRelation.add(request);
    promises.push(sender.save());

    var friendshipRequestSentRelation = receiver.relation("friendshipRequestSent");
    friendshipRequestSentRelation.add(request);

    //add notification
    var notificationRelation = receiver.relation("notifications");
    notificationRelation.add(notification);
    promises.push(receiver.save());

    return Parse.Promise.when(promises);
  }).then(function () {
    console.log("all objects saved");
    //push message to the owner.
    var query = new Parse.Query(Parse.Installation);
    query.equalTo('userId', receiver.id);
    Parse.Push.send({
      where: query, // Set our Installation query
      data: {
        alert: sender.get("firstName")+" wants to be friend of you",
        title: sender.get("firstName")+" wants to be friend of you",
        badge: "Increment",
        sound: "new.caf",
        body: sender.get("name") + " is requesting your permission to become your friend.",
        userInfo: "{User:" + senderID + ", type:friendship_request}",
        requestID: request.id,
        type: "notice",
        notificationID: notification.id
      }
    }, {
      success: function() {
        // Push was successful
        var requestQuery = new Parse.Query(EWFriendRequest);
        requestQuery.include("receiver");
        requestQuery.include("sender");
        requestQuery.get(request.id).then(function(request){
          response.success(request);
        });
      },
      error: function(error) {
        // Handle error
        response.error("error: " + error.message);
      }
    });
  });
});

Parse.Cloud.define("sendFriendshipAcceptanceToUser", function(request, response) {
  Parse.Cloud.useMasterKey();
  var senderID = request.params.sender;
  var receiverID = request.params.receiver;
  var sender;
  var receiver;
  var request;
  var notification;
  var EWFriendRequest = Parse.Object.extend("EWFriendRequest");

  var querySender = new Parse.Query(Parse.User);
  querySender.get(senderID).then(function (object) {
    sender = object;
    var queryReceiver = new Parse.Query(Parse.User);
    return queryReceiver.get(receiverID);
  }).then(function (object) {
    receiver = object;
    var queryRequest = new Parse.Query(EWFriendRequest);
    queryRequest.equalTo("receiver", sender);
    queryRequest.equalTo("sender", receiver);
    return queryRequest.find();
  }).then(function (list) {
    if (list.length > 0) {
      request = list[0];
      request.set("status", "friend_request_friended");
      return request.save();
    } else {
      console.log("Didn't find request");
      response.error("Friend request not found");
    }
  }).then(function (object) {

    console.log("saved request");
    //create notification
    var EWNotification = Parse.Object.extend("EWNotification");
    notification = new EWNotification();
    notification.set("importance", 0);
    notification.set("sender", senderID);
    notification.set("receiver", receiverID);
    notification.set("owner", receiver);
    notification.set("type", "friendship_accepted");
    notification.set("userInfo",  {User:senderID, owner:receiverID, type: "notice", sendername: sender.get("name") });
    if(request) notification.set("friendRequestID", request.id);

    return notification.save();
  }).then(function (notification) {

    console.log("saved notification");
    var promises = [];
    //add relation
    var notificationsRelation = receiver.relation("notifications");
    notificationsRelation.add(notification);

    //friends relation
    var friendsRelation = sender.relation("friends");
    friendsRelation.add(receiver);
    promises.push(sender.save());

    var friendedRelation = receiver.relation("friends");
    friendedRelation.add(sender);
    promises.push(receiver.save());

    return Parse.Promise.when(promises);

  }).then(function () {
    console.log("saved all objects");
    //push message to the owner.
    var query = new Parse.Query(Parse.Installation);
    //query.equalTo('username', ownerObject.get("username"));
    query.equalTo('userId', receiver.id);
    Parse.Push.send({
      where: query, // Set our Installation query
      data: {
        alert: sender.get("firstName")+" accepted your friendship request!",
        title: sender.get("firstName")+" accepted your friendship request!",
        badge: "Increment",
        sound: "new.caf",
        body: sender.get("name") + " has approved your friendship request.",
        type: "notice",
        userInfo: "{User:" + senderID + ", type:friendship_accepted}",
        notificationID: notification.id
      }
    }, {
      success: function() {
        // Push was successful
        var requestQuery = new Parse.Query(EWFriendRequest);
        requestQuery.include("receiver");
        requestQuery.include("sender");
        requestQuery.get(request.id).then(function(request){
          response.success(request);
        });
      },
      error: function(error) {
        // Handle error
        console.log("push error: " + error.message);
        response.error("error: " + error.message);
      }
    });
  });
});


Parse.Cloud.define("getWokeVoice", function(request, response) {
  var currentUserId = request.params.userId;
  var query = new Parse.Query(Parse.User);
  var newMedia;
  query.get(currentUserId).then(function(user){
    console.log("Current user: " + user.get("name"));
    var query = new Parse.Query(Parse.User);
    query.equalTo("username", "woke");
    return query.find();
  }, function (error) {
    console.log("Failed to find current user: ", error.message);
  }).then(function (woke) {
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
    return mediaFileQuery.find();
  }, function (list, error) {
    console.log("failed to find Woke: " + error.message);
  }).then(function (voices) {
    console.log("Get Woke voices: "+voices.length);
    var n = Math.floor(Math.random() * voices.length);
    console.log("Random voice chosen: "+n);
    voiceFile = voices[n];
    media.set("mediaFile", voiceFile);
    return media.save();
  }, function (list, error) {
    console.log("cannot find woke voices");
    response.error("Cannot find woke voices: ", + error.message);
  }).then(function (media) {
    newMedia = media;
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
    return user.save();
  }, function(error){
    console.log("Relation mediaFile->media failed: "+error.message);
  }).then(function (user) {
    response.success(newMedia);
    console.log("Woke voice (" +newMedia.id +") returned");
  }, function (error) {
    // Handle error
    console.error("Failed to send push");
    console.log("Failed to send push for test media: "+error.message);
  });

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
      console.log("User is up to date, skip user");
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
  Parse.Cloud.useMasterKey();
  var userID = request.params.userID;
  var email = request.params.email;
  console.log("query email" + email);
  var facebookID = request.params.facebookID;

  //types
  var EWNotification = Parse.Object.extend("EWNotification");
  var EWSocial = Parse.Object.extend("EWSocial");

  //query against all EWSocial's stored info, detect existing relation
  var newUser;
  var query = new Parse.Query(Parse.User);
  var relatedUsers = [];
  query.get(userID).then( function(user){
    newUser = user;
    //query email in addressBook
    var contactsQuery = new Parse.Query(EWSocial);
    contactsQuery.equalTo("addressBookFriends", email);
    return contactsQuery.find();
  }).then(function (socials) {
    console.log("Found "+socials.length+" addressbook email connection");
    //save users list
    socials.forEach(function (social) {
      var user = social.get("owner");
      console.log(user.id);
      relatedUsers.push(user);
    });
    //query email in facebook
    var facebookQuery = new Parse.Query(EWSocial);
    facebookQuery.equalTo("facebookFriends", facebookID);
    return facebookQuery.find();
  }).then(function (socials) {
    console.log("Found "+socials.length+" facebook connection");
    //add fb users
    socials.forEach(function (social) {
      var user = social.get("owner");
      console.log(user.id);
      relatedUsers.push(user);
    });
    //send notification and EWNotification
    var notifications = [];
    relatedUsers.forEach(function (user) {
      var notification = new EWNotification;
      notification.set("importance", 0);
      notification.set("sender", userID);
      notification.set("receiver", user.id);
      notification.set("owner", user);
      notification.set("type", "new_user");
      notification.set("userInfo",  {User:userID, owner:user.id, type: "notice", sendername: newUser.get("firstName") });
      notifications.push(notification);
    });
    return Parse.Object.saveAll(notifications);
  }).then(function(notifications){

    console.log("Saved "+notifications.length+" notifications");

    var users = [];
    notifications.forEach(function (notification) {
      //save users
      var user = notification.get("owner");
      var notificationRelation = user.relation('notifications');
      notificationRelation.add(notification);
      users.push(user);

      //send push notifications
      var pushQuery = new Parse.Query(Parse.Installation);
      query.equalTo('objectId', user.id);
      Parse.Push.send({
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
          console.log("New user push sent to " + user.id);
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
    console.log("Saved "+users.length+" users");
    response.success(users);
  }, function (error) {
    console.log("failed to save all users")
    response.error(error);
  })
});


//=================Add search string to user==================
Parse.Cloud.beforeSave("_User", function(request, response) {
  var user = request.object;

  var searchString;
  if (user.get("firstName")) searchString = user.get("firstName").toLowerCase();
  if (user.get("lastName")) searchString = searchString + " " + user.get("lastName").toLowerCase();
  if (user.get("email")) searchString = searchString + " " + user.get("email").toLowerCase();
  if (user.get("city")) searchString = searchString + " " + user.get("city").toLowerCase();
  user.set("searchString", searchString);
  console.log("saved search string for user "+user.id+" "+searchString);

  var pref = user.get("preference");
  if (!pref || Object.keys(pref).length === 0) {
    //need to set default preference
    console.log("User "+user.id+"missing preference, set to default");
    user.set("preference", {"BedTimeNotification":true,"DefaultTone":"Autumn Spring.caf","FirstTime":true,"SkipTutorial":false,"SleepDuration":8,"SocialLevel":"Everyone","buzzSound":"default"});
  }
  response.success();
});

Parse.Cloud.beforeSave("EWSocial", function(request, response) {
  var social = request.object;
  var facebookIDs = [];
  var friends = social.get("facebookFriends");
  for (var key in friends) {
    if (friends.hasOwnProperty(key)) {
      facebookIDs.push(key);
    }
  }
  social.set("facebookFriendsArray", facebookIDs);

  var emails = [];
  var addressBookFriends = social.get("addressBookFriends");
  if (addressBookFriends) {
    addressBookFriends.forEach(function (emailNamePair) {
      var email = emailNamePair.email;
      if (email != null) {
        emails.push(email);
      };
      
    });
    social.set("addressBookFriendsEmailArray", emails);
  };
  
  console.log("saved search string for social "+social.id);

  response.success();
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
