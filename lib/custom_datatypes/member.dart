class Member
{
  String name;
  String manualLocation;
  int institutionID;
  int id;
  late String floor;
  late String building;
  late String room;
  //int buildingID;

  Member(this.name, this.manualLocation, this.institutionID, this.id)
  {
    List<String> manualLocationList = manualLocation.split("/");
    building = manualLocationList[0];
    floor = manualLocationList[1];
    room = manualLocationList[2];
  }

  void changeManualLocation(String newManualLocation)
  {
    manualLocation = newManualLocation;
    List<String> manualLocationList = manualLocation.split("/");
    building= manualLocationList[0];
    floor = manualLocationList[1];
    room = manualLocationList[2];
  }
}