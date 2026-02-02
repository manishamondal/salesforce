@IsTest
public class HelloWorldTest {
    @IsTest
    static void testHello() {
        String result = HelloWorld.sayHello();
        System.assertEquals('Hello from Jenkins CI/CD!', result);
    }
}
