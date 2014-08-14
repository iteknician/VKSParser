//
//  VKSAppDelegate.m
//  VKS_Parser
//
//  Created by Vikas Rajpurohit on 18/07/14.
//  Copyright (c) 2014 Vikas. All rights reserved.
//

#import "VKSAppDelegate.h"

#import "VKSXML.h"



@implementation VKSAppDelegate





- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.

    
    [self getXML];
//        VLog(@"hello vikas");
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    return YES;
}

-(void)getXML {
    
    
    
    // Create a success block to be called when the async request completes
    VKSXMLSuccessBlock successBlock = ^(VKSXML *VKSXMLDocument) {


        

   
        
        NSDictionary *dicResult = nil;
        
        if (VKSXMLDocument.rootXMLElement)
         dicResult = [VKSXML dictionaryWithXMLNode:VKSXMLDocument.rootXMLElement];
       
        
     //  dicResult =  [VKSXML getDataAtPath:@"current_observation.image" fromResultObject:dicResult];
        
        VLog(@"%@",[dicResult description]);
        
        
        
        
        

        
    };
    
    // Create a failure block that gets called if something goes wrong
    VKSXMLFailureBlock failureBlock = ^(VKSXML *VKSXMLDocument, NSError * error) {
        NSLog(@"Error! %@ %@", [error localizedDescription], [error userInfo]);
    };
    // Initialize VKSXML with the URL of an XML doc. VKSXML asynchronously loads and parses the file.

    
    NSString *strUrl = @"http://www.w3schools.com/webservices/tempconvert.asmx";
//    NSString *strUrl = @"http://www.mysite.com/myFile.xml";

    NSMutableDictionary *dicParams =[[NSMutableDictionary alloc]initWithObjectsAndKeys:@"50",@"Fahrenheit", nil];

    ;


    [VKSXML newVKSXMLWithURL_SoapRequest:[NSURL URLWithString:strUrl] parameters:dicParams FunctionName:@"FahrenheitToCelsius" success:successBlock failure:failureBlock];
    
    
 //   VKSXML *vksxml =  [[VKSXML alloc]initWithXMLFile:@"sitemap" fileExtension:@"xml" error:nil];
    


//   VKSXML *vksxml = [[VKSXML alloc]initWithURL_SoapRequest:[NSURL URLWithString:strUrl] parameters:dicParams FunctionName:@"FahrenheitToCelsius" success:successBlock failure:failureBlock ];
    
    


}




- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
