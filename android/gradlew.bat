@ECHO OFF
SET APP_HOME=%~dp0
java -Xmx64m -cp "%APP_HOME%\gradle\wrapper\gradle-wrapper.jar" org.gradle.wrapper.GradleWrapperMain %*
