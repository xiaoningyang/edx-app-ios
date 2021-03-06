//
//  NetworkConstants.h
//  edXVideoLocker
//
//  Created by Nirbhay Agarwal on 22/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#ifndef edXVideoLocker_NetworkConstants_h
#define edXVideoLocker_NetworkConstants_h

//NSNotification center constants
#define DOWNLOAD_PROGRESS_NOTIFICATION @"downloadProgressNotification"
#define DOWNLOAD_PROGRESS_NOTIFICATION_VideoID @"downloadProgressNotificationKeyVideoId"
#define DOWNLOAD_PROGRESS_NOTIFICATION_TASK @"downloadProgressNotificationTask"
#define DOWNLOAD_PROGRESS_NOTIFICATION_TOTAL_BYTES_WRITTEN @"downloadProgressNotificationTotalBytesWritten"
#define DOWNLOAD_PROGRESS_NOTIFICATION_TOTAL_BYTES_TO_WRITE @"downloadProgressNotificationTotalBytesToWrite"
#define DOWNLOAD_CANCELLED_NOTIFICATION @"downloadCancelledNotification"
//Request types - used to identify responses - these are used as 'task.taskDescription'
#define TASK_DUMMY_IP @"DUMMY IP"
#define TASK_DUMMY_GET @"DUMMY GET"

#define REQUEST_USER_DETAILS @"User details"
#define REQUEST_COURSE_ENROLLMENTS @"Courses user has enrolled in"



// edX Constants


// TODO: move the remaining things that mention edx.org into config
#define URL_EXTENSION_VIDEOS @".mp4"
#define URL_LOGIN @"/login"
#define URL_USER_DETAILS @"/api/mobile/v0.5/users"
#define URL_COURSE_ENROLLMENTS @"/course_enrollments/"
#define URL_VIDEO_SUMMARY @"/api/mobile/v0.5/video_outlines/courses/"
#define URL_COURSE_HANDOUTS @"/handouts"
#define URL_COURSE_ANNOUNCEMENTS @"/updates"
#define URL_RESET_PASSWORD  @"/password_reset/"
#define URL_SUBSTRING_VIDEOS @"edx-course-videos"
#define URL_SUBSTRING_ASSETS @"asset/"
#define AUTHORIZATION_URL @"/oauth2/access_token"
#define URL_GET_USER_INFO @"/api/mobile/v0.5/my_user_info"
#define URL_SOCIAL_LOGIN @"login_oauth_token"
// For Closed Captioning
#define URL_VIDEO_SRT_FILE @"/api/mobile/v0.5/video_outlines/transcript/"
#endif
