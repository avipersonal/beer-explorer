@isTest
public with sharing class BeerControllerTest {
  @TestSetup
  static void makeData() {
    test.startTest();
    list<Beer__c> beerRecords = new List<Beer__c>();
    for (integer i = 0; i < 200; i++) {
      beerRecords.add(
        new Beer__c(
          Name = 'Aardmonnik' + i,
          Price__c = 500,
          Alcohol__c = 8,
          brewery_name__c = 'De Struise Brouwers',
          Id__c = '6',
          brewery_id__c = '172',
          Tags__c = 'old brown',
          Total_Quantity__c = 1000
        )
      );
    }
    beerRecords.add(
      new beer__c(
        Name = 'Suisen Fire',
        Price__c = 500,
        Alcohol__c = 8,
        brewery_name__c = 'De Struise Brouwers',
        Id__c = '6',
        brewery_id__c = '172',
        Tags__c = 'old brown',
        Total_Quantity__c = 1000
      )
    );
    if (!beerRecords.isEmpty()) {
      insert beerRecords;
    }
    Coupon__c defaultCoupon = new Coupon__c(Name = 'Default', Price__c = 0);
    insert defaultCoupon;
    test.stopTest();
  }

  @isTest
  static void testBeerSearch() {
    //Prepare
    string testString1; //null
    string testString2 = ' ';
    string testString3 = 'ardmonnik11';
    string testString4 = [SELECT Name FROM Beer__c WHERE Name = 'Suisen Fire']
    .Name; //checking whitespace in between

    test.startTest();
    list<sobject> sobjList1 = BeerController.searchBeer(testString1);
    list<sobject> sobjList2 = BeerController.searchBeer(testString2);
    list<sobject> sobjList3 = BeerController.searchBeer(testString3);
    list<sobject> sobjList4 = BeerController.searchBeer(testString4);

    test.stoptest();

    System.assertEquals(
      50,
      sobjList1.size(),
      'The Records are not as Expected!'
    );
    System.assertEquals(
      50,
      sobjList2.size(),
      'The Records are not as Expected!'
    );
    System.assertEquals(
      11,
      sobjList3.size(),
      'The Records are not as Expected!'
    );
    System.assertEquals(
      1,
      sobjList4.size(),
      'The Records are not as Expected!'
    );
  }

  @IsTest
  static void testGenerateCartId() {
    test.startTest();

    string cartid = BeerController.generateCartId();

    test.stopTest();

    System.assert(cartid != null, 'The result is null');
    System.assert(cartid.length() > 16, 'The string is not of length 16');
  }
}
