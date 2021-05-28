//
//  SQLProKeywordsHelper.m
//  SQLProCore
//
//  Created by Kyle Hankinson on 2020-06-05.
//  Copyright © 2020 Hankinsoft Development, Inc. All rights reserved.
//

#import <SQLProResources/SQLProKeywordsHelper.h>

@implementation SQLProKeywordsHelper
{
    NSOrderedSet<NSString*>* keywords;
    NSOrderedSet<NSString*>* functions;
    NSOrderedSet<NSString*>* functionsAndKeywords;
}

+ (NSOrderedSet<NSString*>*) defaultKeywords
{
    static NSOrderedSet<NSString*>* defaultKeywords = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // https://github.com/fibo/SQL92-keywords/blob/master/index.json
        NSString * keywordsPath = [[NSBundle bundleForClass: SQLProKeywordsHelper.class] pathForResource: @"SQLProKeywords"
                                                                                                  ofType: @"json"];

        NSData * data = [NSData dataWithContentsOfFile: keywordsPath];
        NSError * error = nil;
        NSArray<NSString*>* keywords = [NSJSONSerialization JSONObjectWithData: data
                                                                       options: kNilOptions
                                                                         error: &error];

        
        defaultKeywords = [[NSOrderedSet alloc] initWithArray: [keywords sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)]];
    });

    return defaultKeywords;
}

- (id) initWithKeywordsResourceName: (NSString*) keywordsResourceName
              functionsResourceName: (NSString*) functionsResourceName
{
    self = [self init];
    if(self)
    {
        // Setup our targetBundle
        NSBundle * targetBundle = [NSBundle bundleForClass: SQLProKeywordsHelper.class];

        // Setup our sqlKeywords
        NSMutableArray * sqlKeywords = nil;
        sqlKeywords = [[NSArray alloc] initWithContentsOfFile: [targetBundle pathForResource: keywordsResourceName ofType: @"plist"]].mutableCopy;

        if(nil == sqlKeywords)
        {
            NSString * keywordsPath = [targetBundle pathForResource: keywordsResourceName
                                                             ofType: @"json"];

            NSData * data = [NSData dataWithContentsOfFile: keywordsPath];
            NSError * error = nil;
            NSArray<NSString*>* keywords = [NSJSONSerialization JSONObjectWithData: data
                                                                           options: kNilOptions
                                                                             error: &error];

            sqlKeywords = [keywords sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)].mutableCopy;
        }
        else
        {
            NSString * json = [self toJSONKeywords: sqlKeywords];
            NSLog(@"JSON: %@", json);
        }

        [sqlKeywords addObjectsFromArray: SQLProKeywordsHelper.defaultKeywords.array];
        [sqlKeywords sortUsingSelector: @selector(localizedCaseInsensitiveCompare:)];

        // Setup our sqlKeywords
        NSArray * sqlFunctions =
            [[NSArray alloc] initWithContentsOfFile: [targetBundle pathForResource: functionsResourceName ofType: @"plist"]];

        sqlFunctions = [sqlFunctions sortedArrayUsingSelector: @selector(localizedCaseInsensitiveCompare:)];

        if(nil == sqlFunctions)
        {
            NSString * functionsPath = [targetBundle pathForResource: functionsResourceName
                                                             ofType: @"json"];

            NSData * data = [NSData dataWithContentsOfFile: functionsPath];
            NSError * error = nil;
            NSDictionary<NSString*,NSDictionary*>* functions = [NSJSONSerialization JSONObjectWithData: data
                                                                                               options: kNilOptions
                                                                                                 error: &error];

            sqlFunctions = [functions.allKeys sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)].mutableCopy;
        }
        else
        {
            NSString * json = [self toJSONFunctions: sqlFunctions];
            NSLog(@"JSON: %@", json);
        }

        keywords  = [NSOrderedSet orderedSetWithArray: sqlKeywords];
        functions = [NSOrderedSet orderedSetWithArray: sqlFunctions];

        NSMutableArray* found = @[].mutableCopy;
        for(NSString * keyword in keywords)
        {
            if(NSNotFound != [sqlFunctions indexOfObject: keyword.uppercaseString])
            {
                [found addObject: keyword];
            }
        }

        NSAssert(0 != sqlKeywords.count, @"Keywords cannot be empty.");
        NSAssert(0 != sqlFunctions.count, @"Functions cannot be empty.");

        NSMutableSet * allFunctionsAndKeywords = [NSMutableSet set];

        [allFunctionsAndKeywords addObjectsFromArray: sqlKeywords];
        [allFunctionsAndKeywords addObjectsFromArray: sqlFunctions];

        // Set our sorted set
        functionsAndKeywords = [NSOrderedSet orderedSetWithArray: [allFunctionsAndKeywords.allObjects sortedArrayUsingSelector: @selector(localizedCaseInsensitiveCompare:)]];
    }

    return self;
} // End of initWithBundle:resourceName:

- (NSString*) toJSONKeywords: (NSArray<NSString*>*) keywords
{
    keywords = [keywords valueForKeyPath: @"uppercaseString"];
    NSError * error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject: [keywords sortedArrayUsingSelector: @selector(localizedCaseInsensitiveCompare:)]
                                                       options: NSJSONWritingPrettyPrinted
                                                         error: &error];

    NSString *jsonString = [[NSString alloc] initWithData: jsonData
                                                 encoding: NSUTF8StringEncoding];

    return jsonString;
} // End of toJSON:

- (NSString*) toJSONFunctions: (NSArray<NSString*>*) functions
{
    functions = [functions valueForKeyPath: @"uppercaseString"];
    functions = [functions sortedArrayUsingSelector: @selector(localizedCaseInsensitiveCompare:)];

    NSMutableDictionary * outArray = @{}.mutableCopy;
    for(NSString * function in functions)
    {
        outArray[function] = @{@"descriptionMarkup": @""};
    }

    NSError * error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject: outArray
                                                       options: NSJSONWritingPrettyPrinted | NSJSONWritingSortedKeys
                                                         error: &error];

    NSString *jsonString = [[NSString alloc] initWithData: jsonData
                                                 encoding: NSUTF8StringEncoding];

    return jsonString;
} // End of toJSON:

- (NSOrderedSet<NSString*>*) keywords
{
    return keywords;
}

- (NSOrderedSet<NSString*>*) functions
{
    return functions;
}

- (NSOrderedSet<NSString*>*) functionsAndKeywords
{
    return functionsAndKeywords;
} // End of functionsAndKeywords

@end
