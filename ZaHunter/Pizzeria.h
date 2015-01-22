//
//  Pizzeria.h
//  ZaHunter
//
//  Created by Yi-Chin Sun on 1/21/15.
//  Copyright (c) 2015 Yi-Chin Sun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface Pizzeria : NSObject

@property NSString *address;
@property CLLocationDistance distanceFromUser;
@property MKMapItem *mapItem;

@end
