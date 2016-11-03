
//
#define kVerySmallValue (0.000001)
#import "UIColor+hexadecimal.h"
#import "ViewController.h"
#import <GoogleMaps/GoogleMaps.h>
#import "GMDraggableMarkerManager.h"
#import "MarkerModel.h"
#import <stdlib.h>

@interface ViewController ()<GMSMapViewDelegate,UITextFieldDelegate,GMDraggableMarkerManagerDelegate>
{
    GMSMapView *mapView_;
    GMSMutablePath *shapePath;
    GMSPolygon *shape;
    NSString *latitude;
    NSString *longitude;
    CLLocationCoordinate2D arr[20];
    int i;
    CLLocationCoordinate2D lastCoordinate,newCoordinate;
    int index;
    int z;
    NSMutableArray *shapesArr,*markermodelArr,*polygoneArr;
    NSMutableDictionary *markerDict;
    int count;
    CGFloat areaLbY;
    MarkerModel *mModel;
    UILabel *lb;
}
@property (strong, nonatomic, readwrite) GMDraggableMarkerManager *draggableMarkerManager;
@end

@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    
    shapesArr=[NSMutableArray new];
    markermodelArr=[NSMutableArray new];
    polygoneArr=[NSMutableArray new];
    areaLbY=600;
    i=0;
    z=-1;
    count=0;
    _addressTF.delegate=self;
    mapView_ = [GMSMapView mapWithFrame:CGRectMake(0, 100, 800, 500) camera:nil];
    mapView_.myLocationEnabled = YES;
    mapView_.delegate=self;
    mapView_.mapType = kGMSTypeHybrid;
    shapePath = [[GMSMutablePath alloc] init];
    [self.view addSubview:mapView_];
    [self.view setBackgroundColor:[UIColor colorFromHexString:@"#F05A28"]];
}
-(void)textFieldDidEndEditing:(UITextField *)textField{
    
    [_addressTF resignFirstResponder];
}


- (void)mapView:(GMSMapView *)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate
{
    arr[i]=coordinate;
    i++;
    z++;
    
    GMSMarker *marker = [GMSMarker markerWithPosition:coordinate];
    marker.position =coordinate;
    [marker setDraggable:YES];
    //[markerDict setValue:[NSNumber numberWithInt:z] forKey:[NSString stringWithFormat:@"%d",count]];
    mModel=[[MarkerModel alloc]init];
    mModel.section=count;
    mModel.markerIndex=z;
    [marker setUserData:mModel];
    [self.draggableMarkerManager addDraggableMarker:marker];
    marker.map = mapView_;
    
    
}
- (void)mapView:(GMSMapView *)mapView didBeginDraggingMarker:(GMSMarker *)marker
{
    marker.icon=[UIImage imageNamed:@"icon_me"];
    
    lastCoordinate=marker.position;
    
    mModel=(MarkerModel*)marker.userData;
    index=mModel.markerIndex;
    
}


- (void)mapView:(GMSMapView *)mapView didDragMarker:(GMSMarker *)marker
{
    //NSLog(@">>> mapView:didDragMarker: %@", [marker description]);
}

- (void)mapView:(GMSMapView *)mapView didEndDraggingMarker:(GMSMarker *)marker
{
    //NSLog(@">>> mapView:didEndDraggingMarker: %@", [marker description]);
    
    mModel=(MarkerModel*)marker.userData;
    
  NSLog(@"marker section=%d marker index=%d",mModel.section,mModel.markerIndex);
    
    marker.icon=nil;
    newCoordinate=marker.position;

    //shape.map=nil;
    //[shapePath replaceCoordinateAtIndex:index withCoordinate:newCoordinate];
    
    
    if([shapesArr count]==mModel.section)
    {
        arr[index]=newCoordinate;
    }
    else
    {
        [[shapesArr objectAtIndex:mModel.section] replaceCoordinateAtIndex:index withCoordinate:newCoordinate];
        shape= [polygoneArr objectAtIndex:mModel.section];
        shape.path=  [shapesArr objectAtIndex:mModel.section];
        shape.strokeWidth = 2;
        shape.strokeColor = [UIColor redColor];
        shape.fillColor = [UIColor brownColor];
        shape.map = mapView_;
        double area= GMSGeometryArea([shapesArr objectAtIndex:mModel.section]);
        double km2= area/1000000;
        double ac=  area* 0.00024711;
        _acTF.text=[NSString stringWithFormat:@"%f acres",ac];
        _kmTF.text=[NSString stringWithFormat:@"%f km2",km2];
        _areaLable.text=[NSString stringWithFormat:@"%f m2",area];
    }
}
//- (void)mapView:(GMSMapView *)mapView didCancelDraggingMarker:(GMSMarker *)marker
//{
//    NSLog(@">>> mapView:didCancelDraggingMarker: %@", [marker description]);
//}


- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
}


- (IBAction)clearShapes:(id)sender {
    
    _addressTF.text=@"";
    _areaLable.text=@"0.000m2";
    _kmTF.text=@"0.000km2";
    _acTF.text=@"0.000acres";
    shapePath = [[GMSMutablePath alloc] init];
    [mapView_ clear];
    
    for (int j=0; j<20; j++) {
        arr[j].longitude=0;
        arr[j].latitude=0;
    }
    
    [markermodelArr removeAllObjects];
    [polygoneArr removeAllObjects];
    [shapesArr removeAllObjects];
    i=0;
    z=-1;
    count=0;
    areaLbY=600;
    for (id temp in [self.view subviews])
        {
        if ([temp isKindOfClass:[UILabel class]]) {
            
            UILabel *tempLable=(UILabel*)temp;
            
           if (tempLable.tag==100) {
                
                
            }
            else{
                
                [tempLable removeFromSuperview];
     
            }
        }
    }
}

- (IBAction)searchByAddress:(id)sender {
    
    if ([_addressTF.text isEqualToString:@""]) {
        
        UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"Alert" message:@"please type the location" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
   [_addressTF resignFirstResponder];
    NSString *urlStr=[NSString stringWithFormat:@"http://maps.google.com/maps/api/geocode/json?sensor=false&address=%@",_addressTF.text];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:NSTimeIntervalSince1970];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response,NSData *data,NSError *error)
     {
         
         NSDictionary *dict= [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
         NSLog(@"%@",dict);
         NSArray *temp=   [dict objectForKey:@"results"];
         NSString *address;
         id locations;
      for (id temp1 in temp) {
             
             address=[[[temp1 objectForKey:@"address_components"] objectAtIndex:0] objectForKey:@"long_name"];
             NSLog(@"%@",address);
             locations= [[temp1 objectForKey:@"geometry"] objectForKey:@"location"];
             NSLog(@"%@",locations);
     }
         
         latitude=[locations objectForKey:@"lat"];
         longitude=[locations objectForKey:@"lng"];
         
         GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:[latitude doubleValue]
                                                                 longitude:[longitude doubleValue]
                                                                      zoom:kGMSMaxZoomLevel]
         ;
         [mapView_ setCamera:camera];
         
     }];

}
- (IBAction)createPath:(id)sender {
    // shape.map=nil;
    
    if (i<3) {
        
        UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"Marker Alert" message:@"Should be alteast 2 markers" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"ok", nil];
        [alert show];
        return;
    }
     shapePath = [[GMSMutablePath alloc] init];
    for (int k=0; k<i; k++) {
        
        [shapePath addLatitude:arr[k].latitude longitude:arr[k].longitude];
    }
    
    shape= [GMSPolygon polygonWithPath:shapePath];
    shape.strokeWidth = 2;
    shape.strokeColor = [UIColor redColor];
    shape.fillColor = [UIColor brownColor];
    shape.map = mapView_;
    [shapesArr addObject:shapePath];
    [polygoneArr addObject:shape];
    double area= GMSGeometryArea(shapePath);
    
    lb=[[UILabel alloc]initWithFrame:CGRectMake(90,areaLbY+30+10,220,30)];
    areaLbY=lb.frame.origin.y;
    lb.text=[NSString stringWithFormat:@"%f m2",area];
    [self.view addSubview:lb];
    
    //    double km2= area/1000000;
    //    double ac=  area* 0.00024711;
    //    _acTF.text=[NSString stringWithFormat:@"%f acres",ac];
    //    _kmTF.text=[NSString stringWithFormat:@"%f km2",km2];
   // _areaLable.text=[NSString stringWithFormat:@"%f m2",area];
    
    for (int j=0; j<20; j++) {
        arr[j].longitude=0;
        arr[j].latitude=0;
    }
    i=0;
    z=-1;
    count++;
    // [shapePath removeAllCoordinates];

}

//Due to security reasons i am just sending thed code not xcode pro.if u have any doubts u can ask me.

- (IBAction)zoomOut:(id)sender {
    
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:[latitude doubleValue]
                                                            longitude:[longitude doubleValue]
                                                                 zoom:kGMSMinZoomLevel];
    [mapView_ setCamera:camera];
}
@end
