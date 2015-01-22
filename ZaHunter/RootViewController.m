//
//  RootViewController.m
//  ZaHunter
//
//  Created by Yi-Chin Sun on 1/21/15.
//  Copyright (c) 2015 Yi-Chin Sun. All rights reserved.
//

#import "RootViewController.h"
#import <MapKit/MapKit.h>
#import "Pizzeria.h"
#import "MapViewController.h"

@interface RootViewController () <CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) IBOutlet UITableView *pizzaTableView;
@property (strong, nonatomic) IBOutlet UITextView *textView;
@property CLLocationManager *myLocationManager;
@property NSMutableArray *pizzeriasArray;
@property CLLocation *userLocation;
@property (strong, nonatomic) IBOutlet UISegmentedControl *segmentedControl;

@property NSTimeInterval routeTime;
@property NSMutableString *textString;

@end

@implementation RootViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.myLocationManager = [CLLocationManager new];
    self.textString = [NSMutableString new];
    self.myLocationManager.delegate = self;
    [self.myLocationManager requestWhenInUseAuthorization];
    [self.myLocationManager startUpdatingLocation];
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    for (CLLocation *location in locations)
    {
        if (location.verticalAccuracy < 1000 && location.horizontalAccuracy < 1000)
        {
            self.userLocation = location;
            NSLog(@"Calling find Pizza");
            [self findPizzaNear:self.userLocation];
            [self.myLocationManager stopUpdatingLocation];
            break;
        }
    }
}

-(void)findPizzaNear:(CLLocation *)location
{
    MKLocalSearchRequest *request = [MKLocalSearchRequest new];
    request.naturalLanguageQuery = @"Pizza";
    request.region = MKCoordinateRegionMake(location.coordinate, MKCoordinateSpanMake(0.05,0.05));

    MKLocalSearch *search = [[MKLocalSearch alloc]initWithRequest:request];
    [search startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error)
     {
         NSArray *mapItems = response.mapItems;
         self.pizzeriasArray = [NSMutableArray new];
         for (MKMapItem *mapItem in mapItems)
         {
             Pizzeria *newPizzeria = [Pizzeria new];
             newPizzeria.mapItem = mapItem;
             NSString *address = [NSString stringWithFormat:@"%@ %@\n%@",
                                  mapItem.placemark.subThoroughfare,
                                  mapItem.placemark.thoroughfare,
                                  mapItem.placemark.locality];
             newPizzeria.address = address;
             newPizzeria.distanceFromUser = [newPizzeria.mapItem.placemark.location distanceFromLocation:location]/1000;
             [self.pizzeriasArray addObject:newPizzeria];
         }
         NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"distanceFromUser" ascending:YES];
         NSArray *sortedArray = [self.pizzeriasArray sortedArrayUsingDescriptors:@[sortDescriptor]];
         self.pizzeriasArray = [[NSArray arrayWithArray:sortedArray]mutableCopy];

         [self.pizzaTableView reloadData];
         self.routeTime = 0;
         [self getRouteETA:self.pizzeriasArray];
     }];
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog (@"%@", error);
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    Pizzeria *selectedPizzeria = [self.pizzeriasArray objectAtIndex:indexPath.row];
    cell.textLabel.text = selectedPizzeria.mapItem.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%.02f mi", selectedPizzeria.distanceFromUser];
    return cell;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.pizzeriasArray.count < 4)
    {
        return self.pizzeriasArray.count;
    }
    else
    {
        return 4;
    }
}

-(void)getETAFrom: (MKMapItem *)originMapItem to: (MKMapItem *)destinationMapItem;
{
    //Create a request using current location as the source
    MKDirectionsRequest *request = [MKDirectionsRequest new];

    if ([self.segmentedControl selectedSegmentIndex] == 0)
    {
        request.transportType = MKDirectionsTransportTypeWalking;
    }
    else
    {
        request.transportType = MKDirectionsTransportTypeAutomobile;
    }
    request.source = originMapItem;
    request.destination = destinationMapItem;

    //Get directions for specified request
    MKDirections *directions = [[MKDirections alloc]initWithRequest:request];
    [directions calculateETAWithCompletionHandler:^(MKETAResponse *response, NSError *error)
    {
        //Get time in minutes
        self.routeTime = self.routeTime + (response.expectedTravelTime/60);
        NSString *ETAmessage = [NSString stringWithFormat:@"It will take you a total of %.0f minutes to get to %@ because you insist on being a fattie and stopping at every pizza place. \n", self.routeTime, destinationMapItem.name];
        [self.textString appendString:ETAmessage];
        self.routeTime = self.routeTime + 50;
        self.textView.text = self.textString;
    }];
}

-(void)getRouteETA: (NSMutableArray *)locationsArray
{
    MKPlacemark *placemarkSrc = [[MKPlacemark alloc]initWithCoordinate:self.userLocation.coordinate addressDictionary:nil];
    MKMapItem *mapItemSrc = [[MKMapItem alloc] initWithPlacemark:placemarkSrc];
    mapItemSrc.name = @"your original location";
    if (locationsArray.count >= 4)
    {
        for (int i = 0; i < 4; i++)
        {
            Pizzeria *currentPizzeria = [locationsArray objectAtIndex:i];
            //Find ETA between current pizzeria and previous pizzeria
            if(i != 0)
            {
                Pizzeria *previousPizzeria = [locationsArray objectAtIndex:i-1];
                [self getETAFrom:previousPizzeria.mapItem to:currentPizzeria.mapItem];
            }
            //Find ETA between userLocation and the first and fourth pizzeria
            else if (i == 0)
            {
                [self getETAFrom:mapItemSrc to:currentPizzeria.mapItem];
            }

            if (i == 3)
            {
                [self getETAFrom:currentPizzeria.mapItem to: mapItemSrc];
            }
        }
    }
}


- (IBAction)segmentSwitch:(id)sender
{
    self.routeTime = 0;
    [self.textString setString:@""];
    self.textView.text = self.textString;
    [self getRouteETA:self.pizzeriasArray];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    MapViewController *mvc = segue.destinationViewController;
    mvc.pizzeriasArray = self.pizzeriasArray;
}

@end
