//
//  MyVideosSubSectionViewController.m
//  edXVideoLocker
//
//  Created by Rahul Varma on 30/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "MyVideosSubSectionViewController.h"
#import "EdXInterface.h"
#import "Course.h"
#import "HelperVideoDownload.h"
#import "CourseVideosTableViewCell.h"
#import "AppDelegate.h"
#import "Reachability.h"
#import "VideoPlayerInterface.h"
#import "CustomLabel.h"
#import "StatusMessageViewController.h"
#import "CLPortraitOptionsView.h"
#import "TranscriptsData.h"
#import "UserDetails.h"
#import "DataParser.h"



#define HEADER_HEIGHT 80.0
#define SHIFT_LEFT 40.0
#define ORIGINAL_RIGHT_SPACE_PROGRESSBAR 8
#define VIDEO_VIEW_HEIGHT  225

typedef  enum AlertType {
    
    
    AlertTypeNextVideoAlert,
    AlertTypeDeleteConfirmationAlert,
    AlertTypePlayBackErrorAlert,
    AlertTypeCannotPlayVideo,
    AlertTypeVideoTimeOutAlert,
    AlertTypePlayBackContentUnAvailable
    
}AlertType;



@interface MyVideosSubSectionViewController ()<UITableViewDelegate>
{
    NSIndexPath *clickedIndexpath;
}

@property(strong,nonatomic)VideoPlayerInterface *videoPlayerInterface;
@property(strong,nonatomic)HelperVideoDownload *currentTappedVideo;
@property(strong,nonatomic)NSURL *currentVideoURL;
@property(strong,nonatomic)NSIndexPath *selectedIndexPath;
@property(nonatomic , assign) BOOL isTableEditing;
@property(nonatomic , assign) BOOL selectAll;
@property (nonatomic , strong) NSMutableArray *arr_SelectedObjects;
@property (nonatomic, strong) EdXInterface * dataInterface;
@property (nonatomic , strong) NSMutableArray *arr_SubsectionData;
@property(nonatomic)NSInteger alertCount;


@property (weak, nonatomic) IBOutlet CustomLabel *lbl_videoHeader;
@property (weak, nonatomic) IBOutlet CustomLabel *lbl_videobottom;
@property (weak,nonatomic)  IBOutlet CustomLabel *lbl_section;
@property (weak, nonatomic) IBOutlet UIView  *video_containerView;
@property (strong,nonatomic)IBOutlet NSLayoutConstraint *videoViewHeight;
@property   (weak,nonatomic)IBOutlet UIView *videoVideo;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *TrailingSpaceCustomProgress;

@property (weak, nonatomic) IBOutlet CustomNavigationView *customNavigation;
@property (weak, nonatomic) IBOutlet UITableView *table_SubSectionVideos;
@property (weak, nonatomic) IBOutlet DACircularProgressView *customProgressBar;
@property (weak, nonatomic) IBOutlet UIButton *btn_Downloads;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contraintEditingView;
@property (weak, nonatomic) IBOutlet CustomEditingView *customEditing;
@property (weak, nonatomic) IBOutlet UIButton *btn_SelectAllEditing;

- (IBAction)btn_SelectAllCheckBoxClicked:(id)sender;
@end

@implementation MyVideosSubSectionViewController

#pragma mark - REACHABILITY

- (void)HideOfflineLabel:(BOOL)isOnline
{
    self.customNavigation.lbl_Offline.hidden = isOnline;
    self.customNavigation.view_Offline.hidden = isOnline;
    [self.customNavigation adjustPositionOfComponentsWithEditingMode:_isTableEditing isOnline:isOnline];
}


- (void)reachabilityDidChange:(NSNotification *)notification
{
    Reachability *reachability = (Reachability *)[notification object];
    
    if ([reachability isReachable])
    {
        _dataInterface.reachable = YES;
        
        [self HideOfflineLabel:YES];
        
    } else {
        
        _dataInterface.reachable = NO;
        
        [self HideOfflineLabel:NO];
        
    }
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //Add oserver
    [self addObservers];
    
    
    if (_isTableEditing) {
        self.TrailingSpaceCustomProgress.constant = ORIGINAL_RIGHT_SPACE_PROGRESSBAR + SHIFT_LEFT;
    }
    // Add Observer
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityDidChange:) name:kReachabilityChangedNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showCCPortrait:)
                                                 name:NOTIFICATION_OPEN_CC_PORTRAIT object:nil];


    if (_videoPlayerInterface) {
        [self.videoPlayerInterface videoPlayerShouldRotate];
    }
    
    // Check Reachability for OFFLINE
    if (_dataInterface.reachable)
    {
        [self HideOfflineLabel:YES];
    }
    else
    {
        [self HideOfflineLabel:NO];
    }
    
    // To clear already selected items when traverese back from Download screen.
    [self cancelTableClicked:nil];

    
    self.table_SubSectionVideos.separatorInset = UIEdgeInsetsZero;
#ifdef __IPHONE_8_0
    if (IS_IOS8)
        [self.table_SubSectionVideos setLayoutMargins:UIEdgeInsetsZero];
#endif

}

- (void)navigateBack
{
    [self.view setUserInteractionEnabled:NO];
    [self cancelTableClicked:nil];
    [self removePlayerObserver];
    [self.videoPlayerInterface.moviePlayerController pause];
    [self.videoPlayerInterface.moviePlayerController setFullscreen:NO];
    [self.videoPlayerInterface resetPlayer];
     self.videoPlayerInterface = nil;
    [self.navigationController popViewControllerAnimated:YES];
    
}


-(void)removePlayerObserver{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_NEXT_VIDEO object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_PREVIOUS_VIDEO object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_OPEN_CC_PORTRAIT object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackStateDidChangeNotification object:_videoPlayerInterface.moviePlayerController];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:_videoPlayerInterface.moviePlayerController];
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.view setUserInteractionEnabled:YES];
    
    //set exclusive touch for all btns
    self.customNavigation.btn_Back.exclusiveTouch=YES;
    self.btn_Downloads.exclusiveTouch=YES;
    self.view.exclusiveTouch=YES;
    self.videoVideo.exclusiveTouch=YES;
    

    
    AppDelegate *appD = [[UIApplication sharedApplication] delegate];
        //Hide back button
    [self.navigationItem setHidesBackButton:YES];
    
    [self.navigationController.navigationBar setTranslucent:NO];
    
    // Set custom navigation properties
    self.customNavigation.lbl_TitleView.text = appD.str_NAVTITLE;
    [self.customNavigation.btn_Back addTarget:self action:@selector(navigateBack) forControlEvents:UIControlEventTouchUpInside];

    
    
    // Initialize the interface for API calling
    self.dataInterface = [EdXInterface sharedInterface];
    //set custom progress bar properties
    
    [self.customProgressBar setProgressTintColor:PROGRESSBAR_PROGRESS_TINT_COLOR];
    
    [self.customProgressBar setTrackTintColor:PROGRESSBAR_TRACK_TINT_COLOR];
    
    [self.customProgressBar setProgress:_dataInterface.totalProgress animated:YES];
    
    
    //Init video view and video player
    self.videoPlayerInterface=[[VideoPlayerInterface alloc] init];
    _videoPlayerInterface.videoPlayerVideoView = self.videoVideo;
    self.videoViewHeight.constant=0;
    self.videoVideo.exclusiveTouch=YES;
    
    //Fix for 20px issue for the table view
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    // Call to populate data
    [self getSubsectionVideoDataFromArray];
    
    
    [[self.dataInterface progressViews] addObject:self.customProgressBar];
    [[self.dataInterface progressViews] addObject:self.btn_Downloads];
    [self.customProgressBar setHidden:YES];
    [self.btn_Downloads setHidden:YES];
    
    // Used for autorotation
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:@"UIDeviceOrientationDidChangeNotification" object:nil];

    // Show Custom editing View
    [self.customEditing.btn_Edit addTarget:self action:@selector(editTableClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.customEditing.btn_Delete addTarget:self action:@selector(deleteTableClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.customEditing.btn_Cancel addTarget:self action:@selector(cancelTableClicked:) forControlEvents:UIControlEventTouchUpInside];
    self.btn_SelectAllEditing.hidden = YES;
    self.isTableEditing = NO;     // Check Edit button is clicked
    self.selectAll = NO;     // Check if all are selected
}


- (void)addObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playNextVideo) name:NOTIFICATION_NEXT_VIDEO object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playPreviousVideo) name:NOTIFICATION_PREVIOUS_VIDEO object:nil];

    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTotalDownloadProgress:) name:TOTAL_DL_PROGRESS object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playbackStateChanged:)
                                                 name:MPMoviePlayerPlaybackStateDidChangeNotification object:_videoPlayerInterface.moviePlayerController];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playbackEnded:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification object:_videoPlayerInterface.moviePlayerController];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(downloadCompleteNotification:)
                                                 name:VIDEO_DL_COMPLETE object:nil];

}




#pragma mark - Show CC options in portrait mode

- (void)showCCPortrait:(NSNotification *)notification
{
    NSDictionary *dict = notification.userInfo;
    [[CLPortraitOptionsView sharedInstance] addValueToArray:dict];
    [[CLPortraitOptionsView sharedInstance] addViewToContainerSuperview:self.view];
}


#pragma update total download progress

- (void)downloadCompleteNotification:(NSNotification *)notification
{
    NSDictionary * dict = notification.userInfo;
    
    NSURLSessionTask * task = [dict objectForKey:VIDEO_DL_COMPLETE_N_TASK];
    NSURL * url = task.originalRequest.URL;
    
    if ([EdXInterface isURLForVideo:url.absoluteString])
    {
        [self getSubsectionVideoDataFromArray];
    }
}



-(void)updateTotalDownloadProgress:(NSNotification * )notification{
    
    [self.customProgressBar setProgress:_dataInterface.totalProgress animated:YES];
}


- (void)getSubsectionVideoDataFromArray
{
    // Initialize array
    self.arr_CourseData = [[NSMutableArray alloc] init];
    
    // Initialize array of data to show on table
    self.arr_SubsectionData = [[NSMutableArray alloc] init];
    
    NSMutableArray *arrCourseAndVideo = [[NSMutableArray alloc] initWithArray: [_dataInterface coursesAndVideosForDownloadState:DownloadStateComplete] ];
    
    /*
    <__NSArrayM 0x10c7a3e40>(
            
            {
                course = "<Course: 0x10c78f730>";
                videos =     (
                              "<HelperVideoDownload: 0x10c7aa6b0>"
                              );
            }
     
     )
    */
    
    for (NSDictionary *dict in arrCourseAndVideo)
    {
        Course *course = [dict objectForKey:CAV_KEY_COURSE];
        
        if ([course.name isEqualToString:self.customNavigation.lbl_TitleView.text])
        {
            self.arr_CourseData = [dict objectForKey:CAV_KEY_VIDEOS];
        }
        
    }
    
    
    
   // arr_CourseData --> array of all HelperVideoDownload objects in clicked Course
    
    for (HelperVideoDownload *video in self.arr_CourseData)
    {
        NSMutableArray *arr_section = [[NSMutableArray alloc] init];
        
        // Sorting the data with chapter name and section name
        for (HelperVideoDownload *objvideo in self.arr_CourseData)
        {
            // Compare both chapter names and section names
            if ([video.ChapterName isEqualToString:objvideo.ChapterName ] && [video.SectionName isEqualToString:objvideo.SectionName ])
            {
                [arr_section addObject:objvideo];
            }

        }
        
        
        
        // To Remove the duplicate or rather not add it to the main array.
        // To avoid the re-arranging and other processing
        NSMutableArray *arr_CheckDup = [arr_section mutableCopy];
        
        for (HelperVideoDownload *objvideoCheck in arr_CheckDup)
        {
            for (NSMutableArray *check in self.arr_SubsectionData)
            {
                for (HelperVideoDownload *objV in check)
                {
                    if ([objvideoCheck.ChapterName isEqualToString:objV.ChapterName ] && [objvideoCheck.SectionName isEqualToString:objV.SectionName ])
                    {
                        [arr_section removeObject:objvideoCheck];
                    }
                }
            }
        }
        
        
        if ([arr_section count]>0)
        {
            [self.arr_SubsectionData addObject:arr_section];
        }

    }
    [self.table_SubSectionVideos reloadData];

}





- (BOOL)ChapterNameAlreadyDisplayed:(NSInteger)section
{
    HelperVideoDownload *video = [[self.arr_SubsectionData objectAtIndex:section] objectAtIndex:0];

    //  Below for loop check to resolve MOB-447
    //  Multiple headers for the same Section appear in My Videos
    BOOL ChapnameExists = NO;
    int i;
    
    for (i=0; i < section; i++)
    {
        HelperVideoDownload *videoCompare = [[self.arr_SubsectionData objectAtIndex:i] objectAtIndex:0];
        
        if ([video.ChapterName isEqualToString:videoCompare.ChapterName])
        {
            ChapnameExists = YES;
        }
    }

    return ChapnameExists;
}



#pragma mark TableViewDataSourceDelegate


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    _selectedIndexPath=nil;
    return [self.arr_SubsectionData count];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self.arr_SubsectionData objectAtIndex:section] count];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if ([[self.arr_SubsectionData objectAtIndex:section] count] == 0)
        return nil;
    
    HelperVideoDownload *video = [[self.arr_SubsectionData objectAtIndex:section] objectAtIndex:0];

    BOOL ChapnameExists = [self ChapterNameAlreadyDisplayed:section];
    
    
    UIView *viewMain;
    UIView *viewTop;
    UIView *viewBottom;
    UILabel *chapTitle;
    UILabel *sectionTitle;
    
    if (ChapnameExists)
    {
        
        viewMain = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 30 )];
        
        viewBottom = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 30 )];
        viewBottom.backgroundColor = GREY_COLOR;
        [viewMain addSubview:viewBottom];
        
        sectionTitle = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 300, 30)];
        sectionTitle.text = video.SectionName;
        sectionTitle.font = [UIFont fontWithName:@"OpenSans-Semibold" size:14.0f];
        sectionTitle.textColor = [UIColor blackColor];
        [viewMain addSubview:sectionTitle];

    }
    else
    {
        
        viewMain = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, HEADER_HEIGHT )];
        
        viewTop = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 50 )];
        viewTop.backgroundColor = [UIColor colorWithRed:62.0/255.0 green:66.0/255.0 blue:71.0/255.0 alpha:1.0];
        [viewMain addSubview:viewTop];
        
        
        viewBottom = [[UIView alloc] initWithFrame:CGRectMake(0, 50, 320, 30 )];
        viewBottom.backgroundColor = GREY_COLOR;
        [viewMain addSubview:viewBottom];
        
        
        chapTitle = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 300, 50)];
        chapTitle.text = video.ChapterName;
        chapTitle.font = [UIFont fontWithName:@"OpenSans-Semibold" size:14.0f];
        chapTitle.textColor = [UIColor whiteColor];
        [viewMain addSubview:chapTitle];
        
        
        sectionTitle = [[UILabel alloc] initWithFrame:CGRectMake(20, 50, 300, 30)];
        sectionTitle.text = video.SectionName;
        sectionTitle.font = [UIFont fontWithName:@"OpenSans-Semibold" size:14.0f];
        sectionTitle.textColor = [UIColor blackColor];
        [viewMain addSubview:sectionTitle];
        
    }
    
    
    
    return viewMain;
    
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    BOOL ChapnameExists = [self ChapterNameAlreadyDisplayed:section];

    if (ChapnameExists)
    {
        return 30;
    }
    else
        return HEADER_HEIGHT;
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString * cellIndentifier = @"CellCourseVideo";
        
    CourseVideosTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIndentifier];
    
    NSArray *videos = [self.arr_SubsectionData objectAtIndex:indexPath.section];
    cell.btn_Download.hidden = YES;
    HelperVideoDownload *obj_video = [videos objectAtIndex:indexPath.row];
    cell.lbl_Title.text = obj_video.str_VideoTitle;
    if ([cell.lbl_Title.text length]==0) {
        cell.lbl_Title.text = @"(Untitled)";
    }
    double size = [obj_video.size doubleValue];
    float result = ((size/1024)/1024);
    cell.lbl_Size.text = [NSString stringWithFormat:@"%.2fMB",result];
    
    if (!obj_video.duration)
        cell.lbl_Time.text = @"NA";
    else
        cell.lbl_Time.text = [AppDelegate timeFormatted: [NSString stringWithFormat:@"%.1f", obj_video.duration]];
    

    
    //Played state
    UIImage * playedImage;
    if (obj_video.watchedState == PlayedStateWatched) {
        playedImage = [UIImage imageNamed:@"ic_watched.png"];
    }
    else if (obj_video.watchedState == PlayedStatePartiallyWatched) {
        playedImage = [UIImage imageNamed:@"ic_partiallywatched.png"];
    }
    else {
        playedImage = [UIImage imageNamed:@"ic_unwatched.png"];
    }
    cell.img_VideoWatchState.image = playedImage;
    
    
    if (self.isTableEditing)
    {
        // Unhide the checkbox and set the tag
        cell.btn_CheckboxDelete.hidden = NO;
        cell.btn_CheckboxDelete.tag = (indexPath.section * 100) + indexPath.row ;
        [cell.btn_CheckboxDelete addTarget:self action:@selector(selectCheckbox:) forControlEvents:UIControlEventTouchUpInside];
        
        // Toggle between selected and unselected checkbox
        if (obj_video.isSelected)
        {
            [cell.btn_CheckboxDelete setImage:[UIImage imageNamed:@"ic_checkbox_active.png"] forState:UIControlStateNormal];
        }
        else
        {
            [cell.btn_CheckboxDelete setImage:[UIImage imageNamed:@"ic_checkbox_default.png"] forState:UIControlStateNormal];
        }
             
    }
    else
    {
        cell.btn_CheckboxDelete.hidden = YES;
        cell.btn_CheckboxDelete.hidden = YES;
        if(self.currentTappedVideo==obj_video && !self.isTableEditing){
            [self setSelectedCellAtIndexPath:indexPath tableView:tableView];
            _selectedIndexPath=indexPath;
            
        }

    }
#ifdef __IPHONE_8_0
    if (IS_IOS8)
        [cell setLayoutMargins:UIEdgeInsetsZero];
#endif
    
    return cell;
}


-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    
    
        UIView *backview=[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 50)];
        [backview setBackgroundColor:SELECTED_CELL_COLOR];
        cell.selectedBackgroundView=backview;
        if(indexPath==_selectedIndexPath){
            [cell setSelected:YES animated:NO];
        }

    
}



-(void)setSelectedCellAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView{
    
    UITableViewCell *cell=[tableView cellForRowAtIndexPath:indexPath];
    [cell setSelected:YES animated:YES];
    
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // To avoid showing selected cell index of old video when new video is played
    _dataInterface.selectedCCIndex = -1;
    _dataInterface.selectedVideoSpeedIndex = -1;

    
    clickedIndexpath = indexPath;
   
    if (!_isTableEditing)
    {
        // To check and diable the Previous button on the player
        [self CheckIfFirstVideoPlayed:indexPath];

        // To check and diable the NExt button on the player
        [self CheckIfLastVideoPlayed:indexPath];
        

        [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:_selectedIndexPath, nil] withRowAnimation:UITableViewRowAnimationNone];
        _selectedIndexPath=indexPath;
        
        [self playVideoForIndexPath:indexPath];
    }
    
    [tableView reloadData];
}



-(void)playVideoForIndexPath:(NSIndexPath *)indexPath{
    
    NSArray *videos = [self.arr_SubsectionData objectAtIndex:indexPath.section];
    
    HelperVideoDownload *obj = [videos objectAtIndex:indexPath.row];
    
    // Assign this for Analytics
    _dataInterface.selectedVideoUsedForAnalytics = obj;

    // Set the path of the downloaded videos
    [_dataInterface downloadTranscripts:obj];
    
    NSFileManager *filemgr = [NSFileManager defaultManager];
    NSString *slink = [obj.filePath stringByAppendingPathExtension:@"mp4"];
    if (![filemgr fileExistsAtPath:slink]) {
        NSError *error = nil;
        [filemgr createSymbolicLinkAtPath:[obj.filePath stringByAppendingPathExtension:@"mp4"] withDestinationPath:obj.filePath error:&error];
       
        if (error) {
            
            [self showAlert:AlertTypePlayBackErrorAlert];
            
        }
    }
    
   
    
    //stop current video
    [_videoPlayerInterface.moviePlayerController stop];
    
    self.currentTappedVideo = obj;
    self.currentVideoURL = [NSURL fileURLWithPath:slink];
    self.lbl_videoHeader.text=[NSString stringWithFormat:@"%@ ",self.currentTappedVideo.name];
    self.lbl_videobottom.text=[NSString stringWithFormat:@"%@ ",obj.name];
    self.lbl_section.text=[NSString stringWithFormat:@"%@\n%@",self.currentTappedVideo.SectionName,self.currentTappedVideo.ChapterName ];
	[self.table_SubSectionVideos deselectRowAtIndexPath:indexPath animated:NO];
    self.contraintEditingView.constant = 0;
    [self handleComponentsFrame];
   // [_videoPlayerInterface playVideoFor:obj];
    [_videoPlayerInterface playVideoFor:obj];
    
    // Send Analytics
    [_dataInterface sendAnalyticsEvents:VideoStatePlay WithCurrentTime:self.videoPlayerInterface.moviePlayerController.currentPlaybackTime];
    
}

-(void)handleComponentsFrame{
    
    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
        self.videoViewHeight.constant=VIDEO_VIEW_HEIGHT;
        [self.view layoutIfNeeded];
        
    } completion:^(BOOL finished) {
        
    }];
    
}

- (void)playbackStateChanged:(NSNotification *)notification
{
    
    switch ([_videoPlayerInterface.moviePlayerController playbackState])
    {
        case MPMoviePlaybackStateStopped:
           break;
        case MPMoviePlaybackStatePlaying:
            
            if (_currentTappedVideo.watchedState == PlayedStateWatched)
            {

            }
            else
            {
                //Buffering view

                if (_currentTappedVideo.watchedState != PlayedStatePartiallyWatched)
                    [_dataInterface markVideoState:PlayedStatePartiallyWatched
                                      forVideo:_currentTappedVideo];
                _currentTappedVideo.watchedState = PlayedStatePartiallyWatched;
            }
            
            break;
            break;
        case MPMoviePlaybackStatePaused:
            break;
        case MPMoviePlaybackStateInterrupted:
            break;
        case MPMoviePlaybackStateSeekingForward:
            break;
        case MPMoviePlaybackStateSeekingBackward:
            break;
        default:
            break;
    }
    [self.table_SubSectionVideos reloadData];
    
}



- (void)markPlayedStateOnVideoStopped
{
    int  currentTime=self.videoPlayerInterface.moviePlayerController.currentPlaybackTime;
    int  totalTime=self.videoPlayerInterface.moviePlayerController.duration;
    
    if(currentTime==totalTime && totalTime>0)
    {
         self.videoPlayerInterface.moviePlayerController.currentPlaybackTime=0.0;
        
        
        _currentTappedVideo.watchedState = PlayedStateWatched;
        [_dataInterface markVideoState:PlayedStateWatched
                          forVideo:_currentTappedVideo];
        
        [self.table_SubSectionVideos reloadData];

    }
    
}


- (void)playbackEnded:(NSNotification *)notification
{
    
    int reason = [[[notification userInfo] valueForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue];
    if (reason == MPMovieFinishReasonPlaybackEnded)
    {
         [self markPlayedStateOnVideoStopped];
        
    }else if (reason == MPMovieFinishReasonUserExited) {
   
    }else if (reason == MPMovieFinishReasonPlaybackError)
    {
        if([_currentTappedVideo.str_VideoURL isEqualToString:@""])
            [self showAlert:AlertTypePlayBackContentUnAvailable];
        
    }
    
    
    
}


#pragma mark play previous video from the list

- (void)CheckIfFirstVideoPlayed:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && indexPath.row == 0)
    {
        // Post notification to hide the next button
        // We are playing the last video
        
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_HIDE_PREV_NEXT object:self userInfo:@{KEY_DISABLE_PREVIOUS: @"YES"}];
    }
    else
    {
        // Not the last video id playing.
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_HIDE_PREV_NEXT object:self userInfo:@{KEY_DISABLE_PREVIOUS: @"NO"}];
    }
    
}


-(void)playPreviousVideo{
    
    NSIndexPath *indexPath=[self getPreviousVideoIndex];
    if(indexPath)
    {
        [self CheckIfFirstVideoPlayed:indexPath];
        [self tableView:self.table_SubSectionVideos didSelectRowAtIndexPath:indexPath];
    }
}

-(NSIndexPath *)getPreviousVideoIndex
{
    NSIndexPath *indexPath=nil;
    NSIndexPath *currentIndexPath=clickedIndexpath;
    NSInteger row=currentIndexPath.row;
    NSInteger section=currentIndexPath.section;
    
    // Check for the last video in the list
    if(currentIndexPath.section==0)
    {
        
        if(currentIndexPath.row == 0)
        {
            return nil;
        }
        else
        {
            indexPath=[NSIndexPath indexPathForRow:row-1 inSection:section];
        }
        
    }
    else
    {

        if (row > 0 )
        {
            indexPath=[NSIndexPath indexPathForRow:row-1 inSection:section];
        }
        else
        {
            NSInteger rowcount=[self.table_SubSectionVideos numberOfRowsInSection:section-1];
            indexPath=[NSIndexPath indexPathForRow:rowcount-1 inSection:section-1];
        }
    }
    
    
    return indexPath;
    
}



#pragma mark - Implement next video play functionality

- (void)CheckIfLastVideoPlayed:(NSIndexPath *)indexPath
{
    NSInteger totalSections = [self.table_SubSectionVideos numberOfSections];
    // get last index of the table
    NSInteger totalRows = [self.table_SubSectionVideos numberOfRowsInSection:totalSections-1];
    
    if (indexPath.section == totalSections-1 && indexPath.row == totalRows-1)
    {
        // Post notification to hide the next button
        // We are playing the last video
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_HIDE_PREV_NEXT object:self userInfo:@{KEY_DISABLE_NEXT: @"YES"}];
    }
    else
    {
        // Not the last video id playing.
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_HIDE_PREV_NEXT object:self userInfo:@{KEY_DISABLE_NEXT: @"NO"}];
    }

}


-(void)playNextVideo
{
    NSIndexPath *indexPath=[self getNextVideoIndex];
    if(indexPath)
    {
        
        [self CheckIfLastVideoPlayed:indexPath];
        
        [self tableView:self.table_SubSectionVideos didSelectRowAtIndexPath:indexPath];
        
    }
}


-(void)showAlertForNextLecture{
    
    
    NSIndexPath *indexPath=[self getNextVideoIndex];
    
    if(indexPath){
        
        [self showAlert:AlertTypeNextVideoAlert];
        
    }
    
}

/// get next video index path

-(NSIndexPath *)getNextVideoIndex{
    
    NSIndexPath *indexPath=nil;
    NSIndexPath *currentIndexPath=clickedIndexpath;
    NSInteger row=currentIndexPath.row;
    NSInteger section=currentIndexPath.section;
    
    NSInteger totalSection=[self.table_SubSectionVideos numberOfSections];
    
    // Check for the last video in the list
    if(currentIndexPath.section>=(totalSection-1)){
        
        NSInteger rowcount=[self.table_SubSectionVideos numberOfRowsInSection:totalSection-1];
        if(currentIndexPath.row >= rowcount-1){
           return nil;
        }
        
    }
    // If there are more than one section in the table
    if([self.table_SubSectionVideos numberOfSections] > 1 )
    {
        
        NSInteger rowcount=[self.table_SubSectionVideos numberOfRowsInSection:section];
        
        if(row+1 <rowcount){
            
            indexPath=[NSIndexPath indexPathForRow:row+1 inSection:section];
            
        }else{
            
            NSInteger sectionCount=[self.table_SubSectionVideos numberOfSections];
            
            if(section+1 < sectionCount){
                
                indexPath=[NSIndexPath indexPathForRow:0 inSection:section+1];
                
            }
        }
        
    }else{
        
        // If there is only one section in the table
        
        NSInteger rowcount=[self.table_SubSectionVideos numberOfRowsInSection:section];
        if(row+1 <rowcount){
            
            indexPath=[NSIndexPath indexPathForRow:row+1 inSection:section];
            
        }
    }
    
    return indexPath;
    
}

/// get  current video indexPath

-(NSIndexPath *) getCurrentIndexPath{
    
    if([self.table_SubSectionVideos numberOfSections] > 1)
    {
        
        for (id  array in self.arr_SubsectionData) {
            
            if( [array containsObject:self.currentTappedVideo]  &&[array isKindOfClass:[NSArray class]] ){
                
                NSInteger row=[array indexOfObject:self.currentTappedVideo];
                NSInteger section=[self.arr_SubsectionData indexOfObject:array];
                return [NSIndexPath indexPathForRow:row inSection:section];
                
            }
            
        }
    }
    
    return [NSIndexPath indexPathForRow:0 inSection:0] ;
    
}





#pragma mark - Orientation methods

- (void) orientationChanged:(id)object
{
    [[CLPortraitOptionsView sharedInstance] removeSelfFromSuperView];
}


- (BOOL)shouldAutorotate
{
    return YES;
}


- (void)didReceiveMemoryWarning
{
    ELog(@"MemoryWarning MyVideosSubSectionViewController");
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)dealloc{

}



- (void)viewWillDisappear:(BOOL)animated
{
    if(self.navigationController.topViewController != self)
    {
        [[CLPortraitOptionsView sharedInstance] removeSelfFromSuperView];
        [self.videoPlayerInterface.moviePlayerController pause];
    }

    [self removePlayerObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VIDEO_DL_COMPLETE object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:TOTAL_DL_PROGRESS object:nil];
    

}





#pragma mark - USED WHILE EDITING

- (void)cancelTableClicked:(id)sender
{
    [self.customNavigation adjustPositionOfComponentsWithEditingMode:NO isOnline:[_dataInterface reachable]];
    // set isSelected to NO for all the objects
    for (NSArray *arr in self.arr_SubsectionData)
    {
        for (HelperVideoDownload *videos in arr)
        {
            videos.isSelected = NO;
        }
    }
    
    [self.arr_SelectedObjects removeAllObjects];
    
    [self disableDeleteButton];

    // SHIFT THE PROGRESS TO LEFT
    self.TrailingSpaceCustomProgress.constant = ORIGINAL_RIGHT_SPACE_PROGRESSBAR;
    
    [self hideComponentsOnEditing:NO];
    [self.table_SubSectionVideos reloadData];
    
}


- (void)hideComponentsOnEditing:(BOOL)hide
{
    self.isTableEditing = hide;
    self.btn_SelectAllEditing.hidden = !hide;

    self.customEditing.btn_Edit.hidden = hide;
    self.customEditing.btn_Cancel.hidden = !hide;
    self.customEditing.btn_Delete.hidden = !hide;
    self.customEditing.imgSeparator.hidden = !hide;
    
    [self.btn_SelectAllEditing setImage:[UIImage imageNamed:@"ic_checkbox_default.png"] forState:UIControlStateNormal];
    self.selectAll = NO;
}


- (void)deleteTableClicked:(id)sender
{

    if (_arr_SelectedObjects.count > 0) {
        NSString * sString = NSLocalizedString(@"THIS_VIDEO", nil);
        if (_arr_SelectedObjects.count > 1) {
            sString =  NSLocalizedString(@"THESE_VIDEOS", nil);
        }
        
        [self showAlert:AlertTypeDeleteConfirmationAlert];
        
    }
    else
    {
        

    }

}

- (void)pop
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)editTableClicked:(id)sender
{
    [self.customNavigation adjustPositionOfComponentsWithEditingMode:YES isOnline:[_dataInterface reachable]];
    self.arr_SelectedObjects = [[NSMutableArray alloc] init];
    
    // SHIFT THE PROGRESS TO LEFT
    self.TrailingSpaceCustomProgress.constant = ORIGINAL_RIGHT_SPACE_PROGRESSBAR + SHIFT_LEFT;
    
    [self hideComponentsOnEditing:YES];
    
    [self.table_SubSectionVideos reloadData];
}


- (void)selectCheckbox:(id)sender
{
    NSInteger section = ([sender tag])/100;
    NSInteger row = ([sender tag])%100;
    
    NSArray *videos = [self.arr_SubsectionData objectAtIndex:section];
    
    HelperVideoDownload *obj_video = [videos objectAtIndex:row];
    
    // change status of the object and reload table
    
    if (obj_video.isSelected)
    {
        obj_video.isSelected = NO;
        [self.arr_SelectedObjects removeObject:obj_video];
    }
    else
    {
        obj_video.isSelected = YES;
        
        [self.arr_SelectedObjects addObject:obj_video];
    }
    
    [self checkIfAllSelected];
    
    [self.table_SubSectionVideos reloadData];
    [self disableDeleteButton];

}


- (void)disableDeleteButton
{
    if ([self.arr_SelectedObjects count] == 0)
    {
        self.customEditing.btn_Delete.enabled = NO;
        [self.customEditing.btn_Delete setBackgroundColor:[UIColor darkGrayColor]];
    }
    else
    {
        [self.customEditing.btn_Delete setBackgroundColor:[UIColor clearColor]];
        self.customEditing.btn_Delete.enabled = YES;
    }
}



- (void)checkIfAllSelected
{
    // check if all the boxes checked on table then show SelectAll checkbox checked
    BOOL flagBreaked = NO;
    
    for (NSArray *arr in self.arr_SubsectionData)
    {
        for (HelperVideoDownload *videos in arr)
        {
            if (!videos.isSelected)
            {
                self.selectAll = NO;
                flagBreaked = YES;
                break;
            }
            else
                self.selectAll = YES;
        }
        
        if (flagBreaked)
            break;
    }
    
    if (self.selectAll)
    {
        [self.btn_SelectAllEditing setImage:[UIImage imageNamed:@"ic_checkbox_active.png"] forState:UIControlStateNormal];
    }
    else
        [self.btn_SelectAllEditing setImage:[UIImage imageNamed:@"ic_checkbox_default.png"] forState:UIControlStateNormal];
    
}

- (IBAction)btn_SelectAllCheckBoxClicked:(id)sender
{
    if (self.selectAll)
    {
        // de-select all the videos to delete
        
        self.selectAll = NO;
        [self.btn_SelectAllEditing setImage:[UIImage imageNamed:@"ic_checkbox_default.png"] forState:UIControlStateNormal];
        
        for (NSArray *arr in self.arr_SubsectionData)
        {
            for (HelperVideoDownload *videos in arr)
            {
                videos.isSelected = NO;
                [self.arr_SelectedObjects removeObject:videos];
            }
        }
    }
    else
    {
        // remove all objects to avoids number problem
        [self.arr_SelectedObjects removeAllObjects];
        
        // select all the videos to delete
        
        self.selectAll = YES;
        [self.btn_SelectAllEditing setImage:[UIImage imageNamed:@"ic_checkbox_active.png"] forState:UIControlStateNormal];
        
        for (NSArray *arr in self.arr_SubsectionData)
        {
            for (HelperVideoDownload *videos in arr)
            {
                videos.isSelected = YES;
                [self.arr_SelectedObjects addObject:videos];

            }
        }
    }
    
    [self.table_SubSectionVideos reloadData];
    
    [self disableDeleteButton];
}


#pragma mark videoPlayer Delegate

-(void)movieTimedOut{
    
    if(!_videoPlayerInterface.moviePlayerController.isFullscreen){
        
        [[StatusMessageViewController sharedInstance] showMessage:NSLocalizedString(@"TIMEOUT_CHECK_INTERNET_CONNECTION", nil)
                                                 onViewController:self.view
                                                         messageY:64
                                                       components:@[self.customNavigation, self.btn_Downloads, self.customProgressBar, self.btn_SelectAllEditing]
                                                       shouldHide:YES];
        [_videoPlayerInterface.moviePlayerController stop];
        
    }else{
        [self showAlert:AlertTypeVideoTimeOutAlert];
    }
    
    
}





- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(alertView.tag==1001){
        if (buttonIndex == 1)
        {

        [self playNextVideo];
        
        }
    }else if(alertView.tag==1002){
        
        
        if (buttonIndex == 1)
        {
            NSInteger deleteCount = 0;
            for (HelperVideoDownload *selectedVideo in self.arr_SelectedObjects)
            {
                // make a copy of array to avoid GeneralException(updation of array in loop) - crashes app
                NSMutableArray *arrCopySubsection = [self.arr_SubsectionData copy];
                
                for (NSMutableArray *arr in arrCopySubsection)
                {
                    NSMutableArray *arrCopy = [arr copy];
                    
                    for (HelperVideoDownload *videos in arrCopy)
                    {
                        if (selectedVideo == videos)
                        {
                            [arr removeObject:videos];
                            
                           [[EdXInterface sharedInterface] deleteDownloadedVideoForVideoId:selectedVideo.video_id completionHandler:^(BOOL success) {
                                selectedVideo.state=DownloadStateNew;
                                selectedVideo.DownloadProgress=0.0;
                                selectedVideo.isVideoDownloading = NO;

                            }];
                           deleteCount++;
                            
                            // if no objects in a particular section then remove the array
                            if ([arr count] == 0)
                            {
                                [self.arr_SubsectionData removeObject:arr];
                            }
                        }
                    }
                }
                
            }
            
            
            
            NSString * sString = @"";
            if (deleteCount > 1) {
                sString = NSLocalizedString(@"s", nil);
            }
            
            // if no objects to show
            if ([self.arr_SubsectionData count] == 0)
            {
                self.btn_SelectAllEditing.hidden = YES;
                [self performSelector:@selector(pop) withObject:nil afterDelay:1.0];
            }
            else
            {
                [[StatusMessageViewController sharedInstance] showMessage:[NSString stringWithFormat:@"%ld %@%@ %@", (long)deleteCount, NSLocalizedString(@"VIDEO", nil), sString , NSLocalizedString(@"DELETED", nil)]
                                                         onViewController:self.view
                                                                 messageY:64
                                                               components:@[self.customNavigation, self.btn_Downloads, self.customProgressBar, self.btn_SelectAllEditing]
                                                               shouldHide:YES];
                
                // clear all objects form array after deletion.
                // To obtain correct count on next deletion process.
                
                [self.arr_SelectedObjects removeAllObjects];
                
                [self.table_SubSectionVideos reloadData];
            }
            
//            [self disableDeleteButton];
            [self cancelTableClicked:nil];

        }
    }else if ( alertView.tag==1005 || alertView.tag==1006){
        
        
    }
    
    
    if(self.alertCount > 0){
        
        self.alertCount=_alertCount-1;
        
    }
    if(self.alertCount==0){
        
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [_videoPlayerInterface setShouldRotate:YES];
        [_videoPlayerInterface orientationChanged:nil];
        
    }
}


-(void)showAlert:(AlertType )alertType{
    
    self.alertCount=_alertCount+1;
    
    if(self.alertCount>=1){
        
        [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
        [_videoPlayerInterface setShouldRotate:NO];
        
    }
    
    
    switch (alertType) {
            case AlertTypeNextVideoAlert:{
            
            UIAlertView *alert=[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"PLAYBACK_COMPLETE_TITLE", nil)
                                                          message:NSLocalizedString(@"PLAYBACK_COMPLETE_MESSAGE", nil)
                                                         delegate:self
                                                cancelButtonTitle:NSLocalizedString(@"PLAYBACK_COMPLETE_CONTINUE_CANCEL", nil)
                                                otherButtonTitles:NSLocalizedString(@"PLAYBACK_COMPLETE_CONTINUE", nil), nil];
            alert.tag=1001;
            alert.delegate=self;
            [alert show];
        }
            break;
            
            
        case AlertTypeDeleteConfirmationAlert:{
            NSString * sString = NSLocalizedString(@"THIS_VIDEO", nil);

            if (_arr_SelectedObjects.count > 1) {
                sString = NSLocalizedString(@"THESE_VIDEOS", nil);
            }
            UIAlertView *alert= [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CONFIRM_DELETE_TITLE", nil)
                                                           message:[NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"CONFIRM_DELETE_MESSAGE", nil) ,sString]
                                                          delegate:self
                                                 cancelButtonTitle:NSLocalizedString(@"CANCEL", nil)
                                                 otherButtonTitles:NSLocalizedString(@"DELETE", nil), nil];
            alert.tag=1002;
            [alert show];
            
        }
            break;
            
        case AlertTypePlayBackErrorAlert:{
             UIAlertView *alert=[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"VIDEO_CONTENT_NOT_AVAILABLE", nil)
                                                          message:nil
                                                         delegate:self
                                                cancelButtonTitle:NSLocalizedString(@"CLOSE", nil)
                                                otherButtonTitles:nil, nil] ;
            
            alert.tag=1003;
            [alert show];
        }
            break;
            
            
        case AlertTypeVideoTimeOutAlert:{
            
            UIAlertView *alert= [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"TIMEOUT", nil)
                                                           message:NSLocalizedString(@"TIMEOUT_CHECK_INTERNET_CONNECTION", nil)
                                                          delegate:self
                                                 cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                 otherButtonTitles:nil];
            alert.tag=1004;
            [alert show];
            
        }
            break;
            
        case AlertTypePlayBackContentUnAvailable:{
            
            UIAlertView *alert= [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"VIDEO_CONTENT_NOT_AVAILABLE", nil)
                                                           message:nil
                                                          delegate:self
                                                 cancelButtonTitle:NSLocalizedString(@"CLOSE", nil)
                                                 otherButtonTitles:nil];
            alert.tag=1005;
            [alert show];
            
            
        }
            break;
        default:
            break;
    }
    
    
    
}



@end