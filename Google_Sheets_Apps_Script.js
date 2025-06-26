var ss = SpreadsheetApp.openById('xxxxxxxxxx');
var sheet = ss.getSheetByName('xxxxxxxx');

function doGet(e){
  //----------------------------------------------------------------------------------
  //write_google_sheet() function in esp32 sketch, is send data to this code block
  //----------------------------------------------------------------------------------
  //get gps data from ESP32
  if (e.parameter == 'undefined') {
    return ContentService.createTextOutput("Received data is undefined");
  }
  //----------------------------------------------------------------------------------
  var dateTime = new Date();
  temperature = e.parameters.temperature;
  humidity = e.parameters.humidity;
  pitch = e.parameters.pitch;
  roll = e.parameters.roll;
  decibel = e.parameter.decibel;
  pm1 = e.parameter.pm1;
  pm2_5 = e.parameter.pm2_5;
  pm10 = e.parameter.pm10;

  //Logger.log('latitude=' + latitude);
  //----------------------------------------------------------------------------------
  var nextRow = sheet.getLastRow() + 1;
  sheet.getRange("A" + nextRow).setValue(dateTime);
  sheet.getRange("B" + nextRow).setValue(dateTime);
  sheet.getRange("C" + nextRow).setValue(temperature);
  sheet.getRange("D" + nextRow).setValue(humidity);
  sheet.getRange("E" + nextRow).setValue(pitch);
  sheet.getRange("F" + nextRow).setValue(roll);
  sheet.getRange("G" + nextRow).setValue(decibel);
  sheet.getRange("H" + nextRow).setValue(pm1);
  sheet.getRange("I" + nextRow).setValue(pm2_5);
  sheet.getRange("J" + nextRow).setValue(pm10);
  //----------------------------------------------------------------------------------
  //returns response back to ESP32
  return ContentService.createTextOutput("Status Updated in Google Sheet");
  //----------------------------------------------------------------------------------
}

//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//Extra Function. Not used in this project.
//planning to use in future projects.
//this function is used to handle POST request
function doPost(e) {
  var val = e.parameter.value;
  
  if (e.parameter.value !== undefined){
    var range = sheet.getRange('A2');
    range.setValue(val);
  }
}
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM