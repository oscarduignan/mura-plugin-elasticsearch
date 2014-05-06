component accessors=true {
    property name="response";

    function init(required response) {
        setResponse(response);
        return this;
    }

    function isJson() {
        if(not isDefined("_isJson"))
            _isJson = isDefined("_json") or isJSON(getResponse().fileContent);
        return _isJson;
    }

    function json() {
        try {
            if (isDefined("_json") or this.isJSON()) {
                _json = deserializeJSON(getResponse().fileContent);
                return _json;
            }
        } catch (any e) { /* pass */ }

        throw(type="HttpResponse.UnableToDecodeJson");
    }

    function getStatusCode() {
        return val(getResponse().statusCode);
    }

}