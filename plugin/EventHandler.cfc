component persistent="false" accessors="true" output="false" extends="mura.plugin.pluginGenericEventHandler" {

    public void function onApplicationLoad(required struct $) {
        variables.pluginConfig.addEventHandler(this);
        getServiceFactory().declareBean("MuraUtils", "ElasticSearch.MuraUtils");
        getServiceFactory().declareBean("HttpRequestService", "ElasticSearch.HttpRequestService");
        getServiceFactory().declareBean("ElasticSearchService", "ElasticSearch.ElasticSearchService", true, { host = getPlugin("ElasticSearch").getSetting("host") });
        getServiceFactory().declareBean("MuraElasticSearchService", "ElasticSearch.MuraElasticSearchService");
    }

    public void function onContentSave(required struct $) {
        getBean("MuraElasticSearchService").update(content=$.getContentBean());
    }

    public void function onContentDelete(required struct $) {
        getBean("MuraElasticSearchService").remove(content=$.getContentBean());
    }

}