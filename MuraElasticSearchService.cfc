/*

    getBean("MuraElasticSearch")
        +updateIndex(content)
        +refreshIndex(siteid)
        +loadContentIntoNewIndices(limit=10)
        -initIndex(siteid)
        -shouldIndex(content)
        -index(content)
        -remove(content)
        -getContentJson(content)
        -getDocument(content)
        -getIndexJson(content)
        -themePath(path)

*/
component extends="mura.cfobject" accessors=true {
    property name="MuraUtils";
    property name="ElasticSearchService";

    function updateIndex(required content) {
        var siteid = content.getSiteID();

        initIndex(siteid);

        insertOrRemove(
            index=siteid,
            content=content
        );

        if (isCurrentlyReindexing(siteid) and not isCurrentIndexForSite(siteid, getNewIndex(siteid))) {
            insertOrRemove(
                index=getNewIndex(siteid),
                content=content
            );
        }

        flagAsIndexed(content);

        announceEvent("onElasticSearchUpdateIndex", {
            siteid=siteid,
            contentBean=content
        });
    }

    function refreshIndex(required siteid) {
        createNewIndex(siteid);

        announceEvent("onElasticSearchRefreshIndex", { siteid=siteid });
    }

    function loadContentIntoNewIndex(required siteid, limit=999)
        hint="run periodically as a scheduled task with a low limit to populate new index in background, or once with a high limit to refresh immediately."
    {
        if (isCurrentlyReindexing(siteid)) {
            var feed = getBean("feed");
            feed.setSiteId(siteid);
            feed.addParam(
                field="elasticSearchLastIndexed",
                condition="lt",
                criteria=getMuraSite(siteid).getValue("elasticSearchLastIndexed"),
                datatype="timestamp"
            );
            feed.addParam(
                relationship="OR",
                field="elasticSearchLastIndexed",
                condition="is",
                criteria="NULL"
            );
            feed.setMaxItems(limit);

            var it = feed.getIterator().setNextN(limit);
            if (it.recordCount()) {
                while( it.hasNext() ) {
                    var content = it.next();
                    insertOrRemove(getNewIndex(siteid), content);
                    flagAsIndexed(content);
                }
            } else {
                makeNewIndexCurrentIndexForSite(siteid);
            }
        }
    }

    function isCurrentlyReindexing(required siteid) {
        return len(getNewIndex(siteid));
    }

    function isCurrentIndexForSite(required siteid, required index) {
        return structKeyExists(getElasticSearchService().getAliases(alias=siteid).json(), index);
    }

    function getNewIndex(required siteid) {
       return getMuraSite(siteid).getValue("elasticSearchNewIndex");
    }

    /*** PRIVATE FUNCTIONS **************************************************/

    private function insertOrRemove(required index, required content) {
        if (shouldIndex(content)) {
            insertContent(index, content);
        } else {
            removeContent(index, content);
        }
    }

    private function shouldIndex(required content) {
        return content.getIsOnDisplay() and not content.getSearchExclude();
    }

    private function insertContent(required index, required content) {
        return getElasticSearchService().insertDocument(
            index=index,
            type="muraContent",
            id=content.getContentID(),
            body=getContentJson(content)
        );
    }

    private function removeContent(required index, required content) {
        return getElasticSearchService().removeDocument(
            index=index,
            type="muraContent",
            id=content.getContentID()
        );
    }

    private function getContentJson(required content) {
        var contentJson = renderEvent("onElasticSearchGetContentJson", {
            siteid=content.getSiteID(),
            contentBean=content
        }); 

        return (len(contentJson)
            ? contentJson
            : serializeJson(getDocument(content)));
    }

    private function getDocument(required content) {
        return {
            "title"=content.getTitle(),
            "path"=content.getPath(),
            "type"=content.getType(),
            "subType"=content.getSubType(),
            "body"=content.getBody(),
            "summary"=content.getSummary()
        };
    }

    private function initIndex(required siteid) {
        if (not getElasticSearchService().indexExists(siteid)) {
            var newIndex = createNewIndex(siteid);
            getElasticSearchService().createAlias(name=siteid, index=newIndex);
        }
    }

    function createNewIndex(required siteid) {
        var newIndex = createIndexName(siteid);
        var siteBean = getMuraSite(siteid);
        getElasticSearchService().createIndex(name=newIndex, body=getIndexJson(siteid));
        siteBean.setValue("elasticSearchNewIndex", newIndex);
        siteBean.setValue("elasticSearchLastIndexed", now());
        siteBean.save();
        return newIndex;
    }

    private function createIndexName(required siteid) {
        return siteid & dateformat(now(), "_yyyy-mm-dd_") & TimeFormat(now(), "HH-mm-ss");
    }

    private function getIndexJson(siteid) {
        var indexJson = renderEvent("onElasticSearchGetIndexJson", {
            siteid=siteid
        }); 

        if (not len(indexJson)) {
            indexJson = fileRead(
                (fileExists(getThemePath(siteid, "elasticsearch.json"))
                    ? getThemePath("elasticsearch.json")
                    : "indexdefaults.json")
            );
        }

        return indexJson;
    }

    private function getThemePath(required siteid, required path) {
        return getMuraSite(siteid).getThemeAssetPath() & "/" & path;
    }

    private function announceEvent(required name, required event) {
        return getMuraUtils().announceEvent(name, event);
    }

    private function renderEvent(required name, required event) {
        return getMuraUtils().renderEvent(name, event);
    }

    private function flagAsIndexed(required content) {
        return getMuraUtils().updateExtendedAttribute(
            content,
            "elasticSearchLastIndexed",
            now()
        );
    }

    private function getMuraSite(required siteid) {
        return getMuraUtils().getSite(siteid);
    }

    private function makeNewIndexCurrentIndexForSite(required siteid) {
        var newIndex = getNewIndex(siteid);
        var siteBean = getMuraSite(siteid);
        getElasticSearchService().changeAlias(
            name=siteid,
            index=newIndex,
            previousIndex=siteBean.getValue("elasticSearchCurrentIndex")
        );
        siteBean.setValue("elasticSearchCurrentIndex", newIndex);
        siteBean.setValue("elasticSearchNewIndex", "");
        siteBean.save();
    }

}