global class SendOrderToEBS 
{
    webservice static void createCustomerAndServiceOrder(Id oppId)
    {
        Opportunity opp = [select Id,Account.Name,Bill_To_Address__r.Country__c,Bill_To_Address__r.Postal_Code__c,Bill_To_Address__r.State__c,Bill_To_Address__r.City__c from Opportunity WHERE Id = :oppId LIMIT 1];
        CHANNEL_ORDERS__Customer__c customer = new CHANNEL_ORDERS__Customer__c();
        customer.CHANNEL_ORDERS__Customer_City__c = opp.Bill_To_Address__r.City__c;
        customer.CHANNEL_ORDERS__Customer_Country__c = opp.Bill_To_Address__r.Country__c;
        customer.CHANNEL_ORDERS__Customer_State__c = opp.Bill_To_Address__r.State__c;
        customer.CHANNEL_ORDERS__Customer_ZIP_Postal_Code__c = opp.Bill_To_Address__r.Postal_Code__c;
        customer.CHANNEL_ORDERS__Customer_Company_Name__c = opp.Account.Name;
        customer.CHANNEL_ORDERS__Customer_Org_ID__c = opp.Id;
        insert customer;
        
        CHANNEL_ORDERS__Service_Order__c serviceOrder = new CHANNEL_ORDERS__Service_Order__c();
        serviceOrder.CHANNEL_ORDERS__Customer__c = customer.Id;
        serviceOrder.CHANNEL_ORDERS__Partner_Contract_Rules__c  = Id.valueOf('a5Ko00000008RqmEAE');
        insert serviceOrder;
    }
}