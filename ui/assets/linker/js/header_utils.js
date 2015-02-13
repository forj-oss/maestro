/**
(c) Copyright 2014 Hewlett-Packard Development Company, L.P.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

'use strict';
var forjApp = angular.module('forjApp', ['ngAnimate']);

forjApp.directive('newNotificationBounce', ['forjNotifications', function (forjNotif) {
  var timeout = null;
  return {
    link: function(scope, element) {
      forjNotif.onNewNotification(function(){
        element.addClass('bounce-anim');

        if (timeout) {
          clearTimeout(timeout);
        }

        timeout = setTimeout(function() {
          element.removeClass('bounce-anim');
          timeout = null;
        }, 3000);
      });
    }
  };
}]);

forjApp.directive('showPanelAnim', [function () {
  return {
    link: function(scope, element, attrs) {
      var jqElem = $(element), stdHeight = 0, animCompleted = true;
      var animCompletedFn = function() {
        jqElem.css({opacity: '', height: ''});
        animCompleted = true;
      };

      scope.$watch(attrs.showPanelAnim, function (newVal, oldVal) {
        if (newVal === oldVal) {
          return;
        }

        if (newVal) {// Show panel animation
          if (animCompleted) {
            jqElem.removeClass('hide');
            stdHeight = jqElem.height();
            jqElem.css({opacity: 0, height: 0});
          }

          animCompleted = false;
          jqElem.stop().show().animate({ opacity: 1, height: stdHeight + 'px' }, 300, 'linear', animCompletedFn);
        }
        else {// Hide panel animation
          animCompleted = false;
          jqElem.stop().animate({opacity: 0, height: 0}, 300, 'linear', function(){
            jqElem.addClass('hide');
            animCompletedFn();
          });
        }
      });
    }
  };
}]);

forjApp.factory('forjNotifications', ['$http', '$rootScope', function($http, $rootScope) {

  var time = 3000;// Time in miliseconds to wait for the next pull of notifications.
  var notifications = [], newNotificationEvent = [], notificationRemovedEvent = [],

  isAlreadyIn = function(notif, notificationsSet) {
    for (var i = 0; i < notificationsSet.length; i++) {
      if (notif.id === notificationsSet[i].id) {
        return true;
      }
    }

    return false;
  },

  notificationRemovedEventHandler = function(msg) {
    var index = notifications.indexOf(msg);
    if (index === -1) {
      return console.log('The notification you want to delete does not exist.');
    }

    notifications.splice(index, 1);
    for (var i = 0; i < notificationRemovedEvent.length; i++) {
      notificationRemovedEvent[i](msg);
    }
  },

  newNotificationEventHandler = function(msg) {
    notifications.unshift(msg);
    for (var i = 0; i < newNotificationEvent.length; i++) {
      newNotificationEvent[i](msg);
    }
  },

  updateNotifications = function() {
    $http.get('/notification').success(function(data) {

      var i;
      for (i = 0; i < data.length; i++) {// Find new notifications
        if ( !isAlreadyIn(data[i], notifications) ) {
          newNotificationEventHandler(data[i]);
        }
      }

      for (i = 0; i < data.length; i++) {// Removes old notifications
        if ( !isAlreadyIn(notifications[i], data) ) {
          notificationRemovedEventHandler(notifications[i]);
          i--;// This is here because the line above removes one item from notifications
        }
      }
    });
  };

  // Initialization
  updateNotifications();
  setInterval(function() {
    $rootScope.$apply(updateNotifications);
  }, time);

  return {
    notifications: notifications,
    onNotificationRemoved: function(cb) {
      if (!angular.isFunction) {
        throw {
          name: 'Not a function',
          message: 'The provided argument must be a function.',
        };
      }
      onNotificationRemoved.push(cb);
    },
    onNewNotification: function(cb) {
      if (!angular.isFunction) {
        throw {
          name: 'Not a function',
          message: 'The provided argument must be a function.',
        };
      }
      newNotificationEvent.push(cb);
    },
    delete: function(item) {
      $http.get('/notification/delete/' + item.id)
      .success(function(data) {
        if (!data.success) {
          return console.log(data.error);
        }

        notificationRemovedEventHandler(item);
      });
    },
  };
}]);


forjApp.controller('headerController', ['$scope', 'forjNotifications', function($scope, forjNotif) {

  $scope.showNotificationsPanel = false;
  $scope.notifications = forjNotif.notifications;
  $scope.notificationClick = function() {
    $scope.showNotificationsPanel = !$scope.showNotificationsPanel;
  };
  $scope.removeNotification = function(item) {
    forjNotif.delete(item);
  };
}]);


$(document).ready(function(){
  $('#navlist li').click(function(){
    $('#navlist li').removeClass('active');
    $(this).addClass('active');
    if($(this).attr('id')=='li-home'){
      $('#body').load('/home/index');
    }
    if($(this).attr('id')=='li-projects'){
      $('#container-tools').load('/project/index');
    }
  });
  $('.gravatar').click(function(){
    if( $(this).children('div.user-options').length === 0 ){
      $('.preview').remove();
      $(this).append("<div class='user-options preview'><div id='viewport'></div></div>");
      $(this).children('div.user-options').css('opacity', 0).slideDown(400).animate({ opacity: 1 }, { queue: false, duration: 550 });
      $('div.user-options').children('#viewport').append("<span class='loading-span'>Loading...</span>");
      $('div.user-options').children('#viewport').load('../home/user_options', function(response, status, xhr){
        if (status == 'error') {
          $('.loading-span').fadeOut(300, function(){
            $(this).text('Unable to load the user panel.');
          }).fadeIn(300);
        }else{
          $(this).html(response);
        }
      });
    }else{
      $(this).children('div.user-options').css('opacity', 1).slideUp(400).animate({ opacity: 0 }, { queue: false, duration: 550 }).delay(1000, function(){
        $('div.user-options').remove();
      });
    }
  });
  $('.help').click(function(){
    if( $(this).children('div.help-docs').length === 0 ){
      $('.preview').remove();
      $(this).append("<div class='help-docs preview'><div id='viewport'></div></div>");
      $(this).children('div.help-docs').css('opacity', 0).slideDown(400).animate({ opacity: 1 }, { queue: false, duration: 550 });
      $('div.help-docs').children('#viewport').append("<span class='loading-span'>Loading...</span>");
      $('div.help-docs').children('#viewport').load('../docs/index', function(response, status, xhr){
        if (status == 'error') {
          $('.loading-span').fadeOut(300, function(){
            $(this).text('Unable to load help section.');
          }).fadeIn(300);
        }else{
          $(this).html(response);
        }
      });
    }else{
      $(this).children('div.help-docs').css('opacity', 1).slideUp(400).animate({ opacity: 0 }, { queue: false, duration: 550 }).delay(1000, function(){
        $('div.help-docs').remove();
      });
    }
  });

});
