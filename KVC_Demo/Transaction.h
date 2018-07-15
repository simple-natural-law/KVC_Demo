//
//  Transaction.h
//  KVC_Demo
//
//  Created by 张诗健 on 2018/7/15.
//  Copyright © 2018年 张诗健. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Transaction : NSObject

@property (nonatomic) NSString *payee;   // To whom
@property (nonatomic) NSNumber *amount;  // How much
@property (nonatomic) NSDate *date;      // when

@end
