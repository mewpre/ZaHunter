//
//  MapViewController.m
//  ZaHunter
//
//  Created by Yi-Chin Sun on 1/21/15.
//  Copyright (c) 2015 Yi-Chin Sun. All rights reserved.
//

#import "MapViewController.h"
#import <MapKit/MapKit.h>
#import "Pizzeria.h"

@interface MapViewController ()<MKMapViewDelegate>

@property (strong, nonatomic) IBOutlet MKMapView *mapView;
@property UIImage *icon;

@end

@implementation MapViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.icon = [self scale:[UIImage imageNamed:@"pizza"] toSize:CGSizeMake(30, 30)];
    if (self.pizzeriasArray.count >=4)
    {
        for (int i = 0; i < 4; i++)
        {
            Pizzeria *pizzeria = [self.pizzeriasArray objectAtIndex:i];
            MKPointAnnotation *annotation = [MKPointAnnotation new];
            annotation.coordinate = pizzeria.mapItem.placemark.location.coordinate;
            annotation.title = pizzeria.mapItem.name;
            [self.mapView addAnnotation:annotation];
        }
    }
}

-(void)viewDidAppear:(BOOL)animated
{
    [self.mapView showAnnotations:self.mapView.annotations animated:YES];
}

#pragma mark - MapView Methods
//Gets called for every annotation on map
-(MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    MKPinAnnotationView *pin = [[MKPinAnnotationView alloc]initWithAnnotation:annotation reuseIdentifier:nil];
    pin.image = self.icon;
    pin.canShowCallout = YES;

    UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    [rightButton setTitle:annotation.title forState:UIControlStateNormal];
    [pin setRightCalloutAccessoryView:rightButton];

    return pin;
}

- (UIImage *)scale:(UIImage *)image toSize:(CGSize)size
{
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}

@end
