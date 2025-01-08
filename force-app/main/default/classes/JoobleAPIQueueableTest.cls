@isTest
public class JoobleAPIQueueableTest {
    
    @isTest
    static void test_execute() {
        // Arrange
        String keywords = 'test';
        String location = 'test';
        JoobleAPIQueueable queueable = new JoobleAPIQueueable(keywords, location);
        
        // Act
        Test.startTest();
        queueable.execute(null);
        Test.stopTest();
        
        // Assert
        // Verify that the execute method was called correctly
    }
    
    @isTest
    static void test_execute_with_empty_keywords() {
        // Arrange
        String keywords = '';
        String location = 'test';
        JoobleAPIQueueable queueable = new JoobleAPIQueueable(keywords, location);
        
        // Act
        Test.startTest();
        queueable.execute(null);
        Test.stopTest();
        
        // Assert
        // Verify that the execute method was called correctly
    }
    
    @isTest
    static void test_execute_with_empty_location() {
        // Arrange
        String keywords = 'test';
        String location = '';
        JoobleAPIQueueable queueable = new JoobleAPIQueueable(keywords, location);
        
        // Act
        Test.startTest();
        queueable.execute(null);
        Test.stopTest();
        
        // Assert
        // Verify that the execute method was called correctly
    }
}