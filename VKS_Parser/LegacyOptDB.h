//
//  LegacyOptDB.h
//  Cave
//
//  Created by Mac-1 on 4/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@interface LegacyOptDB : UIViewController {
    
}

+ (NSString *) getDBPath;
+ (void) createeditablecopyofdatabase;
+(NSMutableArray*)getRecords:(NSString *)arrKeys From:(NSString *)tblName;
+(NSMutableArray*)getAllDataFrom:(NSString *)sqlNsStr;
+(NSMutableArray*)getRecordsFromQuery:(NSString *)sqlNsStrQuery;
+(NSMutableArray*)getDistinctDataFrom:(NSString *)tblName:(NSString *)colName;

+(BOOL)DeletePreviousCopyIfExists:(NSString *)strDBName;

+(void)getDBPath:(NSString *)strDBName;


//+(void)getDBPath ;

+(BOOL)prepareDatabaseForExecuteQuery;
+(void) dehydrateAllAndCloseDB;


-(BOOL)insertArray:(NSMutableArray *)arrData toTable:(NSString *)tableName:(NSString*)IsSynced;
+(BOOL)insertDic:(NSMutableDictionary *)data toTable:(NSString *)tableName;
+(BOOL)updateDic:(NSMutableDictionary *)data toTable:(NSString *)tableName forKey:(NSString *)strCompareKey;

+(BOOL)deleteArray :(NSMutableArray *)arrData toTable:(NSString *)tableName CompareKey: (NSString *)CompareKeyValue;

+(BOOL)deleteAllRecordFrom:(NSString *)tblName;
+(int)getNumberFromQuery:(NSString*)sqlNsStr;
+(NSString *)getStringFromQuery:(NSString *)sqlNsStrQuery;
+(void)DisableBackup;
+(BOOL)executeQuery:(NSString*)query;
+(BOOL)executeCreateQuery:(NSString*)query;
+(NSInteger)executeInsertQuery :(NSString *)Query:(BOOL)getPreviousId;
//optional load save
+ (NSMutableArray*) getSavedOptions;
+ (void) deleteSavedOption:(NSString*)ImageId;

+ (NSString *) getOptionId:(NSString*)OptionName;
+ (BOOL)isSavedOptions;
+ (NSString *) getImageId:(NSString*)ImageName;

+ (void)Save_Option:(NSString*)Selections OptionName:(NSString*)OptionName CreatedDate:(NSString*)CreatedDate Comment:(NSString*)Comment WeightKg:(NSString*)WeightKg WeightLb:(NSString*)WeightLb Price:(NSString*)Price;

+ (void)Update_Option:(NSString*)Selections  OptionName:(NSString*)OptionName Comment:(NSString*)Comment WeightKg:(NSString*)WeightKg WeightLb:(NSString*)WeightLb Price:(NSString*)Price  where_id:(NSString*)Id;


+ (BOOL)getOptionName:(NSString*)optionname;


@end
