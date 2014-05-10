<cfoutput>
<plugin>
    <name>Elastic Search</name>
    <package>ElasticSearch</package>
    <directoryFormat>packageOnly</directoryFormat>
    <provider>Binary Vision</provider>
    <providerURL>http://binaryvision.com</providerURL>
    <loadPriority>5</loadPriority>
    <version>0.1.0</version>
    <category>Application</category>
    <ormcfclocation />
    <customtagpaths></customtagpaths>
    <mappings />
    <settings>
        <setting>
            <name>host</name>
            <label>Elastic Search Host</label>
            <hint>The hostname for the Elastic Search instance, for example http://localhost:9200 if it's on the same server with the default port.</hint>
            <type>text</type>
            <required>true</required>
            <validation></validation>
            <regex></regex>
            <message></message>
            <defaultValue>http://localhost:9200</defaultValue>
            <optionlist></optionlist>
            <optionlabellist></optionlabellist>
        </setting>
    </settings>
    <eventHandlers>
        <eventHandler event="onApplicationLoad" component="plugin.EventHandler" persist="false" />
    </eventHandlers>
    <displayobjects>
    </displayobjects>
    <extensions>
        <extension type="Site" subType="Default">
            <attributeset name="Elastic Search" container="Custom">
                <attribute
                    name="ElasticSearchCurrentIndex"
                    label="Elastic Search site index, accessible via alias of the siteid."
                    hint=""
                    type="text"
                    defaultValue=""
                    required="false"
                    validation="None"
                    regex=""
                    message=""
                    optionList=""
                    optionLabelList="" />
                <attribute
                    name="ElasticSearchNewIndex"
                    label="Elastic search index is being refreshed, this is the new index."
                    hint=""
                    type="text"
                    defaultValue=""
                    required="false"
                    validation="None"
                    regex=""
                    message=""
                    optionList=""
                    optionLabelList="" />
                <attribute
                    name="ElasticSearchLastIndexed"
                    label="Last time this sites elastic search index was refreshed."
                    hint=""
                    type="text"
                    required="false"
                    validation="Datetime"
                    regex=""
                    message=""
                    optionList=""
                    optionLabelList="" />
            </attributeset>
        </extension>
        <extension type="Base" subType="Default">
            <attributeset name="Elastic Search" container="Custom">
                <attribute
                    name="ElasticSearchLastIndexedContent"
                    label="Last time processed by elastic search."
                    hint=""
                    type="text"
                    required="false"
                    validation="Datetime"
                    regex=""
                    message=""
                    optionList=""
                    optionLabelList="" />
            </attributeset>
        </extension>
    </extensions>
</plugin>
</cfoutput>