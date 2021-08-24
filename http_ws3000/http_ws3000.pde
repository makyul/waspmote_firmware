
#include <Wasp4G.h>
#include <WaspGPS.h>
#include <WaspSensorAgr_v30.h>

float anemometer;
int vane;

char apn[] = "";
char login[] = "";
char password[] = "";


// SERVER settings
///////////////////////////////////////
char host[] = "connectivity.robonomics.network"; 
uint16_t port = 65;
char resource[] = "/";
///////////////////////////////////////

// variables
int error;
bool status;


char anemometer_str[20];
char vane_str[10];
char latitude[20];
char NS_indicator[20];
char longitude[20];
char EW_indicator[20];
char data[200];

weatherStationClass weather;


void setup()
{
  USB.ON();
  USB.println(F("WS3000"));
  RTC.ON();  

  USB.println(F("Sensors on"));
    //////////////////////////////////////////////////.
  // 1. sets operator parameters
  //////////////////////////////////////////////////
  _4G.set_APN(apn, login, password);


  //////////////////////////////////////////////////
  // 2. Show APN settings via USB port
  //////////////////////////////////////////////////
  _4G.show_APN();

  _4G.httpSetContentType("application/json");
   
  USB.println(F("JSON"));

  Agriculture.ON();

  GPS.ON();  
}


void loop(){


  //////////////////////////////////////////////////
  // 1. Switch ON
  //////////////////////////////////////////////////
    error = _4G.ON();

  if (error == 0)
  {
    USB.println(F("1. 4G module ready..."));

      ///////////////////////////////////////////////////
  // 1. wait for GPS signal for specific time
  ///////////////////////////////////////////////////
  status = GPS.waitForSignal(240);
  
  if( status == true )
  {
    USB.println(F("\n----------------------"));
    USB.println(F("Connected"));
    USB.println(F("----------------------"));
  }
  else
  {
    USB.println(F("\n----------------------"));
    USB.println(F("GPS TIMEOUT. NOT connected"));
    USB.println(F("----------------------"));
  }

    ////////////////////////////////////////////////
    // 2.Reading  data 
    ////////////////////////////////////////////////
    Agriculture.sleepAgr("00:00:00:10", RTC_ABSOLUTE, RTC_ALM1_MODE5, SENSOR_ON, SENS_AGR_PLUVIOMETER);
    anemometer = weather.readAnemometer();
    USB.print(F("Anemometer: "));
    USB.print(anemometer);
    USB.println(F(" km/h"));


    
  switch(weather.readVaneDirection())
  {
  case  SENS_AGR_VANE_N   :  snprintf( vane_str, sizeof(vane_str), "N" );
                             break;
  case  SENS_AGR_VANE_NNE :  snprintf( vane_str, sizeof(vane_str), "NNE" );
                             break;  
  case  SENS_AGR_VANE_NE  :  snprintf( vane_str, sizeof(vane_str), "NE" );
                             break;    
  case  SENS_AGR_VANE_ENE :  snprintf( vane_str, sizeof(vane_str), "ENE" );
                             break;      
  case  SENS_AGR_VANE_E   :  snprintf( vane_str, sizeof(vane_str), "E" );
                             break;    
  case  SENS_AGR_VANE_ESE :  snprintf( vane_str, sizeof(vane_str), "ESE" );
                             break;  
  case  SENS_AGR_VANE_SE  :  snprintf( vane_str, sizeof(vane_str), "SE" );
                             break;    
  case  SENS_AGR_VANE_SSE :  snprintf( vane_str, sizeof(vane_str), "SSE" );
                             break;   
  case  SENS_AGR_VANE_S   :  snprintf( vane_str, sizeof(vane_str), "S" );
                             break; 
  case  SENS_AGR_VANE_SSW :  snprintf( vane_str, sizeof(vane_str), "SSW" );
                             break; 
  case  SENS_AGR_VANE_SW  :  snprintf( vane_str, sizeof(vane_str), "SW" );
                             break;  
  case  SENS_AGR_VANE_WSW :  snprintf( vane_str, sizeof(vane_str), "WSW" );
                             break; 
  case  SENS_AGR_VANE_W   :  snprintf( vane_str, sizeof(vane_str), "W" );
                             break;   
  case  SENS_AGR_VANE_WNW :  snprintf( vane_str, sizeof(vane_str), "WNW" );
                             break; 
  case  SENS_AGR_VANE_NW  :  snprintf( vane_str, sizeof(vane_str), "WN" );
                             break;
  case  SENS_AGR_VANE_NNW :  snprintf( vane_str, sizeof(vane_str), "NNW" );
                             break;  
  default                 :  snprintf( vane_str, sizeof(vane_str), "error" );
                             break;    
  }

  USB.println( vane_str );
  USB.println(F("----------------------------------------------------\n"));
  

    Utils.float2String(anemometer,anemometer_str,6);
    Utils.readSerialID();
      
    sprintf(data,  "{\"ID\":\"%X%X%X%X%X%X%X%X\",\"anemometer\":\"%s\",\"vane\":\"%s\",\"GPS_lat\":\"%s\",\"GPS_lon\":\"%s\"}", 
      _serial_id[0], _serial_id[1], _serial_id[2], _serial_id[3], _serial_id[4], _serial_id[5], _serial_id[6], _serial_id[7], anemometer_str, vane_str, "41.6691551208", "-0.8568933486");//GPS.convert2Degrees(GPS.latitude, GPS.NS_indicator), GPS.convert2Degrees(GPS.longitude, GPS.EW_indicator));

      
//"
//
    ////////////////////////////////////////////////
    // 3. HTTP POST
    ////////////////////////////////////////////////
    USB.println(data);
    
    USB.print(F("2. HTTP POST request..."));

    // send the request
    error = _4G.http( Wasp4G::HTTP_POST, host, port, resource, data);

    // check the answer
    if (error == 0)
    {
      USB.print(F("Done. HTTP code: "));
      USB.println(_4G._httpCode);
      USB.print("Server response: ");
      USB.println(_4G._buffer, _4G._length);
    }
    else
    {
      USB.print(F("Failed. Error code: "));
      USB.println(error, DEC);
    }
  }
  else
  {
    // Problem with the communication with the 4G module
    USB.println(F("4G module not started"));
    USB.print(F("Error code: "));
    USB.println(error, DEC);
  }

  ////////////////////////////////////////////////
  // 3. Powers off the 4G module
  ////////////////////////////////////////////////
  USB.println(F("3. Switch OFF 4G module"));
  _4G.OFF();


  ////////////////////////////////////////////////
  // 4. Sleep
  ////////////////////////////////////////////////
  USB.println(F("4. Enter deep sleep..."));
  PWR.deepSleep("00:00:02:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_ON);

  USB.ON();
  USB.println(F("5. Wake up!!\n\n"));

}
