component extends="mxunit.framework.TestCase" {

    function test_isJson_should_return_true_when_is_valid_json() {
        assertTrue(
            new HttpResponse({fileContent=serializeJson({ test=1 })}).isJson()
        );
    }

    function test_isJson_should_return_false_when_is_invalid_json() {
        assertFalse(
            new HttpResponse({fileContent="invalid json"}).isJson()
        );
    }

    function test_json_should_return_cfml_object_when_is_valid_json() {
        var struct = { test=1 };

        assertEquals(
            new HttpResponse({fileContent=serializeJson(struct)}).json(),
            struct
        );
    }

    function test_json_should_throw_exception_when_is_invalid_json()
        mxunit:expectedException="HttpResponse.UnableToDecodeJson"
    {
        new HttpResponse({fileContent="invalid json"}).json();
    }

}