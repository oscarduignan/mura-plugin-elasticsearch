component extends="mxunit.framework.TestCase" {

    function setUp() {
        body = { test=1 };
        testIndices = [ lcase(createUUID()), lcase(createUUID()) ];
        aliasName = lcase(createUUID());

        elasticSearch = new ElasticSearchService("localhost:9200");
        elasticSearch.setHttpRequestService(new HttpRequestService());
    }

    function tearDown() {
        for (var index in testIndices) {
            if( elasticSearch.indexExists(index) )
                elasticSearch.deleteIndex(index);
        }
    }

/*
    function test_search_should_make_correct_request_when_no_index_or_type() {
        requestArgs = elasticSearch.search(body);
        assertEquals("post", requestArgs.method);
        assertEquals("#host#/_search", requestArgs.url);
        assertEquals(body, requestArgs.body);
    }

    function test_search_should_make_correct_request_when_index_but_no_type() {
        requestArgs = elasticSearch.search(index="testIndex", body=body);
        assertEquals("post", requestArgs.method);
        assertEquals("#host#/testIndex/_search", requestArgs.url);
        assertEquals(body, requestArgs.body);
    }

    function test_search_should_make_correct_request_when_index_and_type() {
        requestArgs = elasticSearch.search(index="testIndex", type="testType", body=body);
        assertEquals("post", requestArgs.method);
        assertEquals("#host#/testIndex/testType/_search", requestArgs.url);
        assertEquals(body, requestArgs.body);
    }

    function test_search_should_throw_exception_when_type_but_no_index()
        mxunit:expectedException="coldfusion.runtime.MissingArgumentException"
    {
        // better for it to search _all indexes when no index? Not sure
        requestArgs = elasticSearch.search(type="testType", body=body);
    }
*/

    function test_indexExists_should_return_false_when_index_does_not_exist() {
        assertFalse(elasticSearch.indexExists(testIndices[1]));
    }

    function test_indexExists_should_return_true_when_index_exists() {
        elasticSearch.createIndex(testIndices[1]);
        assertTrue(elasticSearch.indexExists(testIndices[1]));
    }

    function test_createIndex_should_create_index_when_given_valid_non_existant_index_name() {
        assertFalse(elasticSearch.indexExists(testIndices[1]));
        elasticSearch.createIndex(testIndices[1]);
        assertTrue(elasticSearch.indexExists(testIndices[1]));
    }

    // function test_createIndex_should_?_when_given_an_existing_index_name() {}
    // function test_createIndex_should_?_when_given_an_invalid_index_name() {}

    function test_deleteIndex_should_delete_index_when_given_existing_index_name() {
        elasticSearch.createIndex(testIndices[1]);
        assertTrue(elasticSearch.indexExists(testIndices[1]));
        elasticSearch.deleteIndex(testIndices[1]);
        assertFalse(elasticSearch.indexExists(testIndices[1]));
    }

    // function test_deleteIndex_should_?_when_when_given_non_existant_index_name() {}
    // function test_deleteIndex_should_?_when_when_given_non_existant_index_name() {}

    function test_aliasExists_should_return_false_when_alias_does_not_exist() {
        assertFalse(elasticSearch.aliasExists(testIndices[1]));
    }

    function test_aliasExists_should_return_true_when_alias_exists() {
        elasticSearch.createIndex(testIndices[1]);
        elasticSearch.createAlias(aliasName, testIndices[1]);
        assertTrue(elasticSearch.aliasExists(aliasName));
    }

    function test_removeAlias_should_delete_alias_when_given_existing_alias_name() {
        elasticSearch.createIndex(testIndices[1]);
        elasticSearch.createAlias(aliasName, testIndices[1]);
        assertTrue(elasticSearch.aliasExists(aliasName));
        elasticSearch.removeAlias(aliasName);
        assertFalse(elasticSearch.aliasExists(aliasName));
    }

    // function test_removeAlias_should_?_when_given_non_existant_index_name() {}

    function test_changeAlias_should_change_alias_when_given_an_existing_alias() {
        elasticSearch.createIndex(testIndices[1]);
        elasticSearch.createIndex(testIndices[2]);
        elasticSearch.createAlias(aliasName, testIndices[1]);
        assertTrue(elasticSearch.aliasExists(name=aliasName, index=testIndices[1]));
        assertFalse(elasticSearch.aliasExists(name=aliasName, index=testIndices[2]));
        elasticSearch.changeAlias(aliasName, testIndices[2]);
        assertFalse(elasticSearch.aliasExists(name=aliasName, index=testIndices[1]));
        assertTrue(elasticSearch.aliasExists(name=aliasName, index=testIndices[2]));
    }

    // function test_changeAlias_should_?_when_given_a_non_existant_alias() {}

}