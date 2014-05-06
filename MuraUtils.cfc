component extends="mura.cfobject" accessors=true {

    function announceEvent(required name, event={}, firstOnly=false) {
        return getBean("PluginManager").announceEvent(
            eventToAnnounce=name,
            currentEventObject=(isObject(event) ? event : createEvent(event)),
            index=(firstOnly ? 1 : 0)
        );
    }

    function renderEvent(required name, event={}, firstOnly=true) {
        return getBean("PluginManager").renderEvent(
            eventToAnnounce=name,
            currentEventObject=(isObject(event) ? event : createEvent(event)),
            index=(firstOnly ? 1 : 0)
        );
    }

    function createEvent(required event) {
        return createObject("component", "mura.event").init(event);
    }

    function updateExtendedAttribute(
        required content,
        required name,
        required value
    ) {
        var attributeTypeColumn = (isDate(value) ? "datetimeValue" : (isNumeric(value) ? "numericValue" : "stringValue"));
        var query = new query(datasource=getBean("MuraScope").globalConfig("datasource"));
        query.addParam(name="siteID", value=content.getSiteID(), cfsqltype="cf_sql_varchar");
        query.addParam(name="baseID", value=content.getContentHistID(), cfsqltype="cf_sql_varchar");
        query.addParam(name="attributeName", value=name, cfsqltype="cf_sql_varchar");
        query.addParam(name="attributeValue", value=value, cfsqltype="cf_sql_" & (isDate(value) ? "timestamp" : isNumeric(value) ? "numeric" : "varchar" ));
        query.addParam(name="attributeStringValue", value=value, cfsqltype="cf_sql_varchar");

        // first need to get the id of the attribute from the db
        query.setSQL("SELECT * FROM tclassextendattributes WHERE siteid = :siteID AND name = :attributeName");

        attribute = query.execute().getResult();
        if (attribute.recordCount) {
            query.addParam(name="attributeID", value=attribute.attributeID, cfsqltype="cf_sql_numeric");

            // check if there's existing data set for the attribute for this bit of content
            query.setSQL("SELECT * FROM tclassextenddata WHERE baseID = :baseID AND attributeID = :attributeID");

            if (query.execute().getResult().recordCount) {
                query.setSQL("
                    UPDATE tclassextenddata SET
                        attributeValue = :attributeStringValue,
                        #attributeTypeColumn# = :attributeValue
                    WHERE baseId = :baseID AND attributeID = :attributeID AND siteid = :siteID
                ");
            } else {
                query.setSQL("
                    INSERT INTO tclassextenddata
                    (
                        attributeID,
                        siteID,
                        baseID,
                        attributeValue,
                        #attributeTypeColumn#
                    )
                    VALUES
                    (
                        :attributeID,
                        :siteid,
                        :baseId,
                        :attributeStringValue,
                        :attributeValue
                    )
                ");
            }

            query.execute();
        }
    }

    function getSite(required siteid) {
        return getBean("settingsManager").getSite(siteid);
    }

    /*** PRIVATE FUNCTIONS **************************************************/

}