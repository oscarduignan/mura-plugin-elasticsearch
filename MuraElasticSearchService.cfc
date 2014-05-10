/*

    muraElasticSearch
        removeContent(content)
        updateContent(content)


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
    property name="ConfigBean";

    function update(required content) {
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

    function remove(required content) {
        removeContent(content.getSiteID(), content);
    }

    function refreshIndex(required siteid) {
        createNewIndex(siteid);

        announceEvent("onElasticSearchRefreshIndex", { siteid=siteid });
    }

    function loadContentIntoNewIndex(required siteid, limit=999)
        hint="run periodically as a scheduled task with a low limit to populate new index in background, or once with a high limit to refresh immediately."
    {
        if (isCurrentlyReindexing(siteid)) {
            var remainingContent = getUnindexedContent(siteid, limit);
            if (remainingContent.recordCount()) {
                while( remainingContent.hasNext() ) {
                    var content = remainingContent.next();
                    writeDump(content.getElasticSearchLastIndexedContent());
                    if (shouldIndex(content)) {
                        insertOrRemove(getNewIndex(siteid), content);
                    }
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
            return insertContent(index, content);
        } else {
            return removeContent(index, content);
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

    function getDocument(required content) {
        return {
            "title"=content.getTitle(),
            "path"=content.getPath(),
            "type"=content.getType(),
            "subType"=content.getSubType(),
            "body"=content.getBody(),
            "summary"=content.getSummary(),
            "file"=(
                len(content.getFileID())
                    ? binaryEncode(fileReadBinary(getPathToAssociatedFile(content)), "base64")
                    : ""
            )
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

    private function getPathToAssociatedFile(required content) {
        return getMuraUtils().getPathToAssociatedFile(content);
    }

    private function flagAsIndexed(required content) {
        return getMuraUtils().updateExtendedAttribute(
            content,
            "elasticSearchLastIndexedContent",
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

    function getUnindexedContent(required siteid, required numeric limit) {
        var q = new query(datasource=getConfigBean().getDatasource());
        q.setSQL("
            select
            tcontent.siteid, tcontent.title, tcontent.menutitle, tcontent.restricted, tcontent.restrictgroups, 
            tcontent.type, tcontent.subType, tcontent.filename, tcontent.displaystart, tcontent.displaystop, 
            tcontent.remotesource, tcontent.remoteURL,tcontent.remotesourceURL, tcontent.keypoints, 
            tcontent.contentID, tcontent.parentID, tcontent.approved, tcontent.isLocked, tcontent.contentHistID,tcontent.target, tcontent.targetParams, 
            tcontent.releaseDate, tcontent.lastupdate,tcontent.summary, 
            tfiles.fileSize,tfiles.fileExt,tcontent.fileid, 
            tcontent.tags,tcontent.credits,tcontent.audience, tcontent.orderNo, 
            tcontentstats.rating,tcontentstats.totalVotes,tcontentstats.downVotes,tcontentstats.upVotes, 
            tcontentstats.comments, tparent.type parentType, null as kids, 
            tcontent.path, tcontent.created, tcontent.nextn, tcontent.majorVersion, tcontent.minorVersion, tcontentstats.lockID, tcontentstats.lockType, tcontent.expires, 
            tfiles.filename as AssocFilename,tcontent.displayInterval,tcontent.display,tcontentfilemetadata.altText as fileAltText 
            from tcontent 
            left Join tfiles on (tcontent.fileid=tfiles.fileid) 
            left Join tcontentstats on (tcontent.contentid=tcontentstats.contentid 
            and tcontent.siteid=tcontentstats.siteid) 
            Left Join tcontent tparent on (tcontent.parentid=tparent.contentid 
            and tcontent.siteid=tparent.siteid 
            and tparent.active=1) 
            Left Join tcontentfilemetadata on (tcontent.fileid=tcontentfilemetadata.fileid  and tcontent.contenthistid=tcontentfilemetadata.contenthistid) 
            where 
            tcontent.siteid = 'muracon' 
            AND tcontent.active = 1
            AND tcontent.moduleid = '00000000000000000000000000000000000' 
            AND tcontent.type <>'Module' 
            and ( 
            tcontent.contentHistID NOT IN ( 
            select tclassextenddata.baseID from tclassextenddata 
            inner join tclassextendattributes on (tclassextenddata.attributeID = tclassextendattributes.attributeID) 
            where tclassextendattributes.siteid='muracon' 
            and tclassextendattributes.name= 
            'elasticSearchLastIndexedContent' 
            and 
            datetimevalue 
            > 
            :siteLastIndexed
            ) 
            ) 
            AND 
            ( 
            tcontent.Display = 1 
            OR 
            ( 
            tcontent.Display = 2 
            AND 
            ( 
            ( 
            tcontent.DisplayStart <= now() 
            AND (tcontent.DisplayStop >= now() or tcontent.DisplayStop is null) 
            ) 
            OR 
            tparent.type='Calendar' 
            ) 
            ) 
            ) 
            and (tcontent.mobileExclude is null 
            OR 
            tcontent.mobileExclude in (0,1) 
            ) 
            order by 
            tcontent.lastUpdate desc 
            limit #limit#
        ");
        q.addParam(
            name="siteLastIndexed",
            value=getMuraSite(siteid).getValue("elasticSearchLastIndexed"),
            cfsqltype="cf_sql_timestamp"
        );
        return getBean("contentIterator").setQuery(q.execute().getResult());
    }

}