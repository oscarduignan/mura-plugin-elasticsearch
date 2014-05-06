/*

    getBean("ElasticSearch")
        +search(body, type)
        +createIndex(name, settings)
        +deleteIndex(name, settings)
        +indexExists(name)
        +insertDocument(index, type, id, document)
        +updateDocument(index, type, id, document)
        +removeDocument(index, type, id)
        +documentExists(index, type, id)
        +createAlias()
        +updateAlias()
        +removeAlias()
        +bulkUpdate(operations)
        -getUrl()
        -serializeBody(body)
        -httpRequest()

*/
component accessors=true {
    property name="HttpRequestService";

    function init(required host) {
        variables.host = arguments.host;
    }

    function search(
        required body,
        index="",
        type=""
    ) {
        if (len(type) and not len(index))
            throwMissingArgumentException("Index param is required if you have specified a type param. You can specify index=_all if you want to search across all indices.");

        return makeHttpRequest(
            method="post",
            url=getUrl(index, type, "_search"),
            body=body
        );
    }

    /*** INDEX METHODS ******************************************************/

    function createIndex(
        required name,
        body=""
    ) {
        return makeHttpRequest(
            method="put",
            url=getUrl(name),
            body=body
        );
    }

    function deleteIndex(
        required name
    ) {
        return makeHttpRequest(
            method="delete",
            url=getUrl(name)
        );
    }

    function indexExists(
        required name
    ) {
        return makeHttpRequest(
            method="head",
            url=getUrl(name)
        ).getStatusCode() eq 200;
    }

    /*** ALIAS METHODS ******************************************************/

    function createAlias(
        required name,
        required index
    ) {
        return makeHttpRequest(
            method="post",
            url=getUrl("_alias"),
            body={
                "actions"=[
                    {"add"= {"index"=index, "alias"=name}}
                ]
            }
        );
    }

    function updateAliases(required actions) {
        return makeHttpRequest(
            method="post",
            url=getUrl("_alias"),
            body={
                "actions"=actions
            }
        );
    }

    function getAliases(
        index="",
        alias=""
    ) {
        return makeHttpRequest(
            method="get",
            url=getUrl(index, "_alias", alias)
        );
    }

    function aliasExists(
        required name
    ) {
        return makeHttpRequet(
            method="head",
            url=getUrl("_alias", name)
        ).getStatusCode() eq 200;
    }

    /*** DOCUMENT METHODS ***************************************************/

    function insertDocument(
        required index,
        required type,
        required id,
        required body
    ) {
        return makeHttpRequest(
            method="put",
            url=getUrl(index, type, id),
            body=body
        );
    }

    function updateDocument(
        required index,
        required type,
        required id,
        required body
    ) {
        return makeHttpRequest(
            method="post",
            url=getUrl(index, type, id, "_update"),
            body=body
        );
    }

    function documentExists(
        required index,
        required type,
        required id
    ) {
        return makeHttpRequest(
            method="head",
            url=getUrl(index, type, id)
        );
    }

    function removeDocument(
        required index,
        required type,
        required id
    ) {
        return makeHttpRequest(
            method="delete",
            url=getUrl(index, type, id)
        );
    }
 
    /*** PRIVATE METHODS ****************************************************/

    private function getHost() {
        return variables.host;
    }

    private function getUrl() {
        var href = getHost();

        for(var param in arguments) {
            if(len(arguments[param])) { href = listAppend(href, arguments[param], "/"); }
        }

        return href;
    }

    private function makeHttpRequest() {
        return getHttpRequestService().request(argumentCollection=arguments);
    }

    private function throwMissingArgumentException(message="") {
        throw(
            type="coldfusion.runtime.MissingArgumentException",
            message=message
        );
    }

}