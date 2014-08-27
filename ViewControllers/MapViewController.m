//
//  MapViewController.m
//  MapWithPolygon
//
//  Created by Anjaneyulu Battula on 12/08/14.
//  Copyright (c) 2014 Riktam. All rights reserved.

#define MAP_PADDING 1.1
#define MINIMUM_VISIBLE_LATITUDE 0.01

#import "MapViewController.h"
#import <MapKit/MapKit.h>

@interface MapViewController () <MKMapViewDelegate, CLLocationManagerDelegate>
{
    __block NSMutableArray *latLongForBoundaryMArray;
    NSArray *polygonArray;
    CLLocation *currentLocation;

    CLLocationManager *locationManager;
    MKMapView *regionsMapView;
}

@end

@implementation MapViewController

#pragma mark - View Life cycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        if (IS_OS_7_OR_LATER)
        {
            self.edgesForExtendedLayout = UIRectEdgeNone;
            self.extendedLayoutIncludesOpaqueBars = NO;
            self.automaticallyAdjustsScrollViewInsets = NO;
        }
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    UIBarButtonItem *zoomBarBtnItem = [[UIBarButtonItem alloc] initWithTitle:@"Zoom" style:UIBarButtonItemStyleBordered target:self action:@selector(zoomBtnClicked)];
    self.navigationController.navigationItem.leftBarButtonItem = zoomBarBtnItem;
    self.navigationItem.leftBarButtonItem = zoomBarBtnItem;
    
    NSDictionary *polygon1 = [[NSDictionary alloc] initWithObjectsAndKeys:@"yellow", @"color", @"lineareabuffer", @"filename", @"line", @"type", nil];
    NSDictionary *polygon2 = [[NSDictionary alloc] initWithObjectsAndKeys:@"green", @"color", @"sharedusearea", @"filename", @"polygon", @"type", nil];
    NSDictionary *polygon3 = [[NSDictionary alloc] initWithObjectsAndKeys:@"red", @"color", @"29palms", @"filename", @"polygon", @"type", nil];
    polygonArray = [[NSArray alloc] initWithObjects:polygon1, polygon2, polygon3, nil];

    regionsMapView = [[MKMapView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, [UIScreen mainScreen].bounds.size.height - 64)];
    regionsMapView.delegate = self;
    regionsMapView.showsUserLocation = YES;
    regionsMapView.mapType = MKMapTypeSatellite;
    [self.view addSubview:regionsMapView];
    
    //Location Manager to find out the currentlocation with 100m desired Accuracy
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.distanceFilter = 5.0f;
    locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters; // 100 m
    [locationManager startUpdatingLocation];
    
    UIButton *nearMeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    nearMeBtn.frame = CGRectMake(self.view.frame.size.width - 40, 3, 40, 40);
    [nearMeBtn setImage:[UIImage imageNamed:@"near_me.png"] forState:UIControlStateNormal];
    [nearMeBtn addTarget:self action:@selector(nearMeBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:nearMeBtn];
    
    [self addPolygonsAndPolyLinesToTheRegionsMapView];
    
    CLLocationCoordinate2D checkpoint = CLLocationCoordinate2DMake(34.201182,-116.048491);
    [self pointInsideOverlay:checkpoint];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Developer Methods

- (void)zoomBtnClicked {
    
    [self zoomToAnnotationsBounds:latLongForBoundaryMArray];
}

- (void)nearMeBtnClicked {
    
//#define MAP_PADDING 1.1
//#define MINIMUM_VISIBLE_LATITUDE 0.01

    
    if (currentLocation != nil) {
    
        MKCoordinateRegion region;
        region.center = CLLocationCoordinate2DMake(currentLocation.coordinate.latitude, currentLocation.coordinate.longitude);
//        region.center = CLLocationCoordinate2DMake(17.430081, 78.444311);

        region.span = MKCoordinateSpanMake(0.0018, 0.0018);
//        region.span.latitudeDelta = currentLocation.coordinate.latitude * MAP_PADDING;
//        region.span.latitudeDelta = (region.span.latitudeDelta < MINIMUM_VISIBLE_LATITUDE) ? MINIMUM_VISIBLE_LATITUDE : region.span.latitudeDelta;
//        region.span.longitudeDelta = currentLocation.coordinate.longitude * MAP_PADDING;
        
        MKCoordinateRegion scaledRegion = [regionsMapView regionThatFits:region];
        [regionsMapView setRegion:scaledRegion animated:YES];

    }

}

//adding Polygons and PolyLines to the MapView
- (void)addPolygonsAndPolyLinesToTheRegionsMapView
{
    
//    __block NSMutableArray *latLongForBoundaryMArray = [[NSMutableArray alloc] init];
    latLongForBoundaryMArray = [[NSMutableArray alloc] init];
    
    [polygonArray enumerateObjectsUsingBlock:^(NSDictionary *dic, NSUInteger polygonIdx, BOOL *stop) {
        dic = [polygonArray objectAtIndex:polygonIdx];
        
        //retrieving info from csv file
        NSString *filePath = [[NSBundle mainBundle] pathForResource:[dic objectForKey:@"filename"] ofType:@"csv"];
        NSString *fileContents = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
        NSArray *latLongArray = [fileContents componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        CLLocationCoordinate2D *coords = malloc(sizeof(CLLocationCoordinate2D) * [latLongArray count]);
        
        //adding latitutde,longitutde array strings to the CLLocationCoordinate array
        [latLongArray enumerateObjectsUsingBlock:^(NSString *latLongObj, NSUInteger latLongIdx, BOOL *stop) {
            latLongObj = [latLongArray objectAtIndex:latLongIdx];
            NSArray *latLongPoint = [latLongObj componentsSeparatedByString:@","];
            coords[latLongIdx] = CLLocationCoordinate2DMake([[latLongPoint objectAtIndex:0] doubleValue], [[latLongPoint objectAtIndex:1] doubleValue]);
        }];
        
        //adding polygon,polyline latitude,longitude points to the latLongForBoundaryArray to zoom the ploted area
        [latLongForBoundaryMArray addObjectsFromArray:latLongArray];
        
        //if type is polygon we add latLongArray to the MKPolygon
        if ([[dic objectForKey:@"type"] isEqualToString:@"polygon"]) {
            MKPolygon *polygontemp = [MKPolygon polygonWithCoordinates:coords count:[latLongArray count]];
            polygontemp.title = [dic objectForKey:@"color"];
            free(coords);
            [regionsMapView addOverlay:polygontemp];
        }//if type is line we add latLongArray to the MKPolyline
        else if ([[dic objectForKey:@"type"] isEqualToString:@"line"]) {
            MKPolyline *line = [MKPolyline polylineWithCoordinates:coords count:[latLongArray count]];
            line.title = @"line";
            free(coords);
            [regionsMapView addOverlay:line];
        }
    }];
    
    //to zoom the ploted Area
    [self zoomToAnnotationsBounds:(NSArray*)latLongForBoundaryMArray];
    
}

//checking whether current location is inside polygon or not
-(void)pointInsideOverlay:(CLLocationCoordinate2D )tapPoint
{
    __block BOOL isInside = FALSE;
    
    NSArray *overlaysArray = [regionsMapView overlays];
    [overlaysArray enumerateObjectsUsingBlock:^(id overlayObj, NSUInteger overlayIdx, BOOL *stop) {
        
        overlayObj = [overlaysArray objectAtIndex:overlayIdx];
        
        if ([overlayObj isKindOfClass:[MKPolygon class]]) {
            
            MKPolygon *polygon = (MKPolygon *)overlayObj;
            if ([polygon.title isEqualToString:@"red"]) {
                
                MKPolygonView *polygonView = (MKPolygonView *)[regionsMapView viewForOverlay:overlayObj];
                MKMapPoint mapPoint = MKMapPointForCoordinate(tapPoint);
                CGPoint polygonViewPoint = [polygonView pointForMapPoint:mapPoint];
                BOOL mapCoordinateIsInPolygon = CGPathContainsPoint(polygonView.path, NULL, polygonViewPoint, NO);
                
                //we are checking the points that are inside the overlay
                if (mapCoordinateIsInPolygon ) {
                    isInside = TRUE;
                    NSLog(@"TRUE");
                }
                else {
                    NSLog(@"FALSE");
                }
            }
        }
    }];
    
}

//Zooming the ploted Area
- (void)zoomToAnnotationsBounds:(NSArray *)latLongArray {
    __block CLLocationDegrees minLatitude = DBL_MAX;
    __block CLLocationDegrees maxLatitude = -DBL_MAX;
    __block CLLocationDegrees minLongitude = DBL_MAX;
    __block CLLocationDegrees maxLongitude = -DBL_MAX;
    
    [latLongArray enumerateObjectsUsingBlock:^(NSString *latLongObj, NSUInteger latLongIdx, BOOL *stop) {
        latLongObj = [latLongArray objectAtIndex:latLongIdx];
        NSArray *latLongPoint = [latLongObj componentsSeparatedByString:@","];
        
        double annotationLat = [[latLongPoint objectAtIndex:0] doubleValue];
        double annotationLong = [[latLongPoint objectAtIndex:1] doubleValue];
        minLatitude = fmin(annotationLat, minLatitude);
        maxLatitude = fmax(annotationLat, maxLatitude);
        minLongitude = fmin(annotationLong, minLongitude);
        maxLongitude = fmax(annotationLong, maxLongitude);
    }];
    
    [self setMapRegionForMinLat:minLatitude minLong:minLongitude maxLat:maxLatitude maxLong:maxLongitude];
}


//Passing min,max latitude and min, max longitude to zoom the ploted area
-(void) setMapRegionForMinLat:(double)minLatitude minLong:(double)minLongitude maxLat:(double)maxLatitude maxLong:(double)maxLongitude {
    
    // pad our map by 10% around the farthest annotations
    
    // we'll make sure that our minimum vertical span is about a kilometer
    // there are ~111km to a degree of latitude. regionThatFits will take care of
    // longitude, which is more complicated, anyway.
    
    MKCoordinateRegion region;
    region.center.latitude = (minLatitude + maxLatitude) / 2;
    region.center.longitude = (minLongitude + maxLongitude) / 2;
    
    region.span.latitudeDelta = (maxLatitude - minLatitude) * MAP_PADDING;
    
    region.span.latitudeDelta = (region.span.latitudeDelta < MINIMUM_VISIBLE_LATITUDE)
    ? MINIMUM_VISIBLE_LATITUDE
    : region.span.latitudeDelta;
    
    region.span.longitudeDelta = (maxLongitude - minLongitude) * MAP_PADDING;
    
    MKCoordinateRegion scaledRegion = [regionsMapView regionThatFits:region];
    [regionsMapView setRegion:scaledRegion animated:YES];
    
}

#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    currentLocation = [locations lastObject];
    if (currentLocation.horizontalAccuracy < 0)
        return;
}

#pragma mark - MKMapViewDelegate
//Available in iOS 4.0 and later. Deprecated in iOS 7.0.
- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id )overlay
{
    if ([overlay isKindOfClass:[MKPolygon class]]) {
        MKPolygon *polygonadf = (MKPolygon *)overlay;
        MKPolygonView *polygonView = [[MKPolygonView alloc] initWithPolygon:overlay];
        
        if ([polygonadf.title isEqualToString:@"red"]) {
            polygonView.lineWidth = 5;
            polygonView.strokeColor = [UIColor clearColor];
            polygonView.fillColor = [UIColor redColor];
        }
        if ([polygonadf.title isEqualToString:@"green"]) {
            polygonView.lineWidth = 5;
            polygonView.strokeColor = [UIColor clearColor];
            polygonView.fillColor = [UIColor greenColor];
        }
        return polygonView;
    }
    else if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolylineView *routeLineView = [[MKPolylineView alloc] initWithPolyline:overlay] ;
        //        routeLineView.fillColor = [UIColor yellowColor];
        routeLineView.strokeColor = [UIColor yellowColor];
        routeLineView.lineWidth = 5;
        return routeLineView;
    }
    return nil;
}

//Available in iOS 7.0 and later.
- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id < MKOverlay >)overlay
{
    if ([overlay isKindOfClass:[MKPolygon class]]) {
        MKPolygon *polygonadf = (MKPolygon *)overlay;
        MKPolygonView *polygonView = [[MKPolygonView alloc] initWithPolygon:overlay];
        
        if ([polygonadf.title isEqualToString:@"red"]) {
            polygonView.lineWidth = 5;
            polygonView.strokeColor = [UIColor clearColor];
            polygonView.fillColor = [UIColor redColor];
        }
        if ([polygonadf.title isEqualToString:@"green"]) {
            polygonView.lineWidth = 5;
            polygonView.strokeColor = [UIColor clearColor];
            polygonView.fillColor = [UIColor greenColor];
        }
        
        MKOverlayRenderer *polygonOverlayRenderer = (MKOverlayRenderer *)polygonView;
        return polygonOverlayRenderer;
    }
    else if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolylineView *routeLineView = [[MKPolylineView alloc] initWithPolyline:overlay] ;
        //        routeLineView.fillColor = [UIColor yellowColor];
        routeLineView.strokeColor = [UIColor yellowColor];
        routeLineView.lineWidth = 5;
        
        MKOverlayRenderer *routeLineOverlayRenderer = (MKOverlayRenderer *)routeLineView;
        return routeLineOverlayRenderer;
    }
    return nil;
}

/*
- (void)addPolyLinesToTheRegionsMapView {
    //retrieving info from csv file
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"lineareabuffer" ofType:@"csv"];
    NSString *fileContents = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    NSArray *latLongArray = [fileContents componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    CLLocationCoordinate2D *coordstemp = malloc(sizeof(CLLocationCoordinate2D) * [latLongArray count]);
    
    [latLongArray enumerateObjectsUsingBlock:^(NSString *latLongObj, NSUInteger latLongIdx, BOOL *stop) {
        latLongObj = [latLongArray objectAtIndex:latLongIdx];
        NSArray *latLongPoint = [latLongObj componentsSeparatedByString:@","];
        coordstemp[latLongIdx] = CLLocationCoordinate2DMake([[latLongPoint objectAtIndex:0] doubleValue], [[latLongPoint objectAtIndex:1] doubleValue]);
    }];
    
    MKPolyline *line = [MKPolyline polylineWithCoordinates:coordstemp count:[latLongArray count]];
    line.title = @"line";
    free(coordstemp);
    [regionsMapView addOverlay:line];
}


- (void)addPolygonsToTheRegionsMapView {
    
    //retrieving info from csv file
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"sharedusearea" ofType:@"csv"];
    NSString *fileContents = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    NSArray *latLongArray = [fileContents componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    CLLocationCoordinate2D *coordstemp = malloc(sizeof(CLLocationCoordinate2D) * [latLongArray count]);
    
    [latLongArray enumerateObjectsUsingBlock:^(NSString *latLongObj, NSUInteger latLongIdx, BOOL *stop) {
        latLongObj = [latLongArray objectAtIndex:latLongIdx];
        NSArray *latLongPoint = [latLongObj componentsSeparatedByString:@","];
        coordstemp[latLongIdx] = CLLocationCoordinate2DMake([[latLongPoint objectAtIndex:0] doubleValue], [[latLongPoint objectAtIndex:1] doubleValue]);
    }];
    
    MKPolygon *polygontemp = [MKPolygon polygonWithCoordinates:coordstemp count:[latLongArray count]];
    polygontemp.title = @"green";
    free(coordstemp);
    [regionsMapView addOverlay:polygontemp];
    
}
 */

@end
