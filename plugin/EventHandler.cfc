component persistent="false" accessors="true" output="false" extends="mura.plugin.pluginGenericEventHandler" {

    public void function onApplicationLoad(required struct $) {
        variables.pluginConfig.addEventHandler(this);
        getServiceFactory().declareBean("ElasticSearch", "ElasticSearch.ElasticSearch");
        getServiceFactory().declareBean("MuraElasticSearch", "ElasticSearch.MuraElasticSearch");
    }

}