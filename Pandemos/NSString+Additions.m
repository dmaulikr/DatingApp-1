//
//  NSString+Additions.m
//  Pandemos
//
//  Created by Michael Sevy on 4/8/16.
//  Copyright © 2016 Michael Sevy. All rights reserved.
//

#import "NSString+Additions.h"

@implementation NSString (Additions)

-(NSString *)ageFromBirthday:(NSString *)birthday
{
    //Caculate age from birthday
    NSDateFormatter *formatter = [NSDateFormatter new];
    [formatter setDateFormat:@"MM/dd/yyyy"];
    NSDate *todaysDate = [NSDate date];
    NSDate *birthdateNSDate = [formatter dateFromString:birthday];
    NSDateComponents *ageComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitYear fromDate:birthdateNSDate toDate:todaysDate options:0];
    NSUInteger age = ageComponents.year;
    NSString *ageStr = [NSString stringWithFormat:@"%lu", (unsigned long)age];

    return ageStr;
}
@end
