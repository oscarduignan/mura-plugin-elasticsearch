component extends="mxunit.framework.TestCase" {

    function setUp() {
        body = { test=1 };
        indexName = lcase(createUUID()); // index names must be lowercase

        elasticSearch = new ElasticSearchService("localhost:9200");
        elasticSearch.setHttpRequestService(new HttpRequestService());
    }

    function tearDown() {
        if( elasticSearch.indexExists(indexName) )
            elasticSearch.deleteIndex(indexName);
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
        assertFalse(elasticSearch.indexExists(createUUID()));
    }

    function test_indexExists_should_return_true_when_index_does_exist() {
        // TODO need to think about what to do when actions return an error
        // probably be a good idea to raise a coldfusion exception. Do I do
        // this by parsing response or do I catch errors before the request
        // gets made?
        elasticSearch.createIndex(indexName);
        assertTrue(elasticSearch.indexExists(indexName));
    }

    function test_createIndex_should_create_index_when_given_valid_index_name() {
        assertFalse(elasticSearch.indexExists(indexName));
        elasticSearch.createIndex(indexName);
        assertTrue(elasticSearch.indexExists(indexName));
    }

}