class Member
{
  String name;
  String manualLocation;
  int institutionID;
  int id;
  late String floor;
  late String building;
  late String room;
  String role;
  String memberID;
  String status;
  //int buildingID;

  Member(this.name, this.manualLocation, this.institutionID, this.id, this.role, this.memberID, this.status)
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