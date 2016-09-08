component {

    this.name = 'CampaignMonitorProtocl_TestingSuite' & hash(getCurrentTemplatePath());
    this.sessionManagement = true;
    this.sessionTimeout = createTimeSpan(0, 0, 15, 0);
    this.applicationTimeout = createTimeSpan(0, 0, 15, 0);
    this.setClientCookies = true;

    this.mappings['/tests'] = getDirectoryFromPath(getCurrentTemplatePath());
    rootPath = REReplaceNoCase(this.mappings['/tests'], 'tests(\\|/)', '');
    this.mappings['/root'] = rootPath;
    this.mappings['/cbmailservices'] = rootPath & "modules/cbmailservices";

}