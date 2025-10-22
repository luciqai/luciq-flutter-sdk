package ai.luciq.flutter;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockStatic;

import ai.luciq.bug.BugReporting;
import ai.luciq.flutter.generated.BugReportingPigeon;
import ai.luciq.flutter.modules.BugReportingApi;
import ai.luciq.flutter.util.GlobalMocks;
import ai.luciq.flutter.util.ArgsRegistry;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.mockito.MockedStatic;

import io.flutter.plugin.common.BinaryMessenger;

/**
 * Example demonstrating how mockStatic works in your BugReportingApi tests
 */
public class MockStaticExampleTest {
    
    // 1. DECLARE MOCKED STATIC OBJECTS
    private final BinaryMessenger mMessenger = mock(BinaryMessenger.class);
    private final BugReportingPigeon.BugReportingFlutterApi flutterApi = new BugReportingPigeon.BugReportingFlutterApi(mMessenger);
    private final BugReportingApi api = new BugReportingApi(flutterApi);
    
    // These are the key MockedStatic objects that control static method behavior
    private MockedStatic<BugReporting> mBugReporting;
    private MockedStatic<BugReportingPigeon.BugReportingHostApi> mHostApi;

    @Before
    public void setUp() throws NoSuchMethodException {
        // 2. CREATE MOCKED STATIC OBJECTS
        // This tells Mockito to intercept ALL static method calls on these classes
        mBugReporting = mockStatic(BugReporting.class);
        mHostApi = mockStatic(BugReportingPigeon.BugReportingHostApi.class);
        GlobalMocks.setUp();
    }

    @After
    public void cleanUp() {
        // 3. CLEAN UP MOCKED STATIC OBJECTS
        // CRITICAL: Always close MockedStatic objects to avoid memory leaks
        mBugReporting.close();
        mHostApi.close();
        GlobalMocks.close();
    }

    @Test
    public void testAddHabibaUserConsents_BasicExample() {
        // 4. ARRANGE - Set up test data
        String key = "testKey";
        String description = "Test consent description";
        Boolean mandatory = true;
        Boolean checked = false;
        String actionType = "UserConsentActionType.dropAutoCapturedMedia";

        // 5. ACT - Call the method under test
        api.addHabibaUserConsents(key, description, mandatory, checked, actionType);

        // 6. ASSERT - Verify the static method was called correctly
        // This is where mockStatic shines - it lets you verify static method calls
        mBugReporting.verify(() -> BugReporting.addUserConsent(
            eq(key), 
            eq(description), 
            eq(mandatory), 
            eq(checked), 
            eq(ArgsRegistry.userConsentActionType.get(actionType))
        ));
    }

    @Test
    public void testAddHabibaUserConsents_WithNullActionType() {
        // Test with null actionType
        String key = "testKey";
        String description = "Test consent description";
        Boolean mandatory = false;
        Boolean checked = true;
        String actionType = null;

        api.addHabibaUserConsents(key, description, mandatory, checked, actionType);

        // Verify the static method was called with null actionType
        mBugReporting.verify(() -> BugReporting.addUserConsent(
            eq(key), 
            eq(description), 
            eq(mandatory), 
            eq(checked), 
            eq(actionType) // null
        ));
    }

    @Test
    public void testAddHabibaUserConsents_WithInvalidActionType() {
        // Test with invalid actionType to verify validation
        String key = "testKey";
        String description = "Test consent description";
        Boolean mandatory = true;
        Boolean checked = true;
        String invalidActionType = "InvalidActionType.someInvalidValue";

        // This should throw an exception due to validation
        try {
            api.addHabibaUserConsents(key, description, mandatory, checked, invalidActionType);
            // If we get here, the test should fail
            assert false : "Expected IllegalArgumentException for invalid actionType";
        } catch (IllegalArgumentException e) {
            // Expected behavior - validation should catch invalid actionType
            assert e.getMessage().contains("Invalid actionType");
        }
    }

    @Test
    public void testAddHabibaUserConsents_WithEmptyKey() {
        // Test validation for empty key
        String emptyKey = "";
        String description = "Test consent description";
        Boolean mandatory = true;
        Boolean checked = true;
        String actionType = "UserConsentActionType.dropLogs";

        try {
            api.addHabibaUserConsents(emptyKey, description, mandatory, checked, actionType);
            assert false : "Expected IllegalArgumentException for empty key";
        } catch (IllegalArgumentException e) {
            assert e.getMessage().contains("Key cannot be null or empty");
        }
    }

    @Test
    public void testAddHabibaUserConsents_VerifyAllActionTypes() {
        // Test all valid action types
        String[] validActionTypes = {
            "UserConsentActionType.dropAutoCapturedMedia",
            "UserConsentActionType.dropLogs", 
            "UserConsentActionType.noChat"
        };

        for (String actionType : validActionTypes) {
            String key = "testKey_" + actionType;
            String description = "Test consent for " + actionType;
            Boolean mandatory = true;
            Boolean checked = true;

            api.addHabibaUserConsents(key, description, mandatory, checked, actionType);

            // Verify each call
            mBugReporting.verify(() -> BugReporting.addUserConsent(
                eq(key), 
                eq(description), 
                eq(mandatory), 
                eq(checked), 
                eq(ArgsRegistry.userConsentActionType.get(actionType))
            ));
        }
    }
}

/**
 * HOW MOCKSTATIC WORKS - EXPLAINED:
 * 
 * 1. DECLARATION: MockedStatic<ClassName> variableName;
 *    - This creates a "spy" that intercepts static method calls
 * 
 * 2. CREATION: mockStatic(ClassName.class)
 *    - This tells Mockito to start intercepting static calls
 *    - All static methods on that class become mockable
 * 
 * 3. VERIFICATION: mockedStatic.verify(() -> ClassName.staticMethod(...))
 *    - This verifies that a static method was called with specific parameters
 *    - The lambda syntax () -> ClassName.staticMethod(...) captures the call
 * 
 * 4. STUBBING: mockedStatic.when(() -> ClassName.staticMethod(...)).thenReturn(...)
 *    - This makes static methods return specific values
 *    - Useful when your code depends on static method return values
 * 
 * 5. CLEANUP: mockedStatic.close()
 *    - CRITICAL: Always close to avoid memory leaks and test interference
 * 
 * KEY BENEFITS:
 * - Test isolation: Your code doesn't actually call the real static methods
 * - Verification: You can verify exactly how static methods were called
 * - Control: You can make static methods return specific values for testing
 * - Speed: No real network calls, database operations, etc.
 */
