class Member
{
  String name;
  String manualLocation;
  int institutionID;
  int id;
  late String floor;
  //late String building;
  late String room;
  int buildingID;

  Member(this.name, this.manualLocation, this.institutionID, this.id, this.buildingID)
  {
    List<String> manualLocationList = manualLocation.split("/");
    buildingID = int.parse(manualLocationList[0]);
    floor = manualLocationList[1];
    room = manualLocationList[2];

  }

  void changeManualLocation(String newManualLocation)
  {
    manualLocation = newManualLocation;
    List<String> manualLocationList = newManualLocation.split("/");
    buildingID = int.parse(manualLocationList[0]);
    floor = manualLocationList[1];
    room = manualLocationList[2];
  }
}