package snmp.v3;

class H3CUserTarget {

    String address;
    String securityName2;
    int securityLevel;
    int securityModel;
    int retries;
    long timeout;
    int version;

    public H3CUserTarget(String address, String securityName2, int securityLevel, int securityModel, int retries, long timeout, int version) {
        this.address = address;
        this.securityName2 = securityName2;
        this.securityLevel = securityLevel;
        this.securityModel = securityModel;
        this.retries = retries;
        this.timeout = timeout;
        this.version = version;
    }

    public String getAddress() {
        return address;
    }

    public String getSecurityName2() {
        return securityName2;
    }

    public int getSecurityLevel() {
        return securityLevel;
    }

    public int getSecurityModel() {
        return securityModel;
    }

    public int getRetries() {
        return retries;
    }

    public long getTimeout() {
        return timeout;
    }

    public int getVersion() {
        return version;
    }
}