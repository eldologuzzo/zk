
<%@ page import="java.sql.*" %>
<%@ page import="java.io.*" %>
<%@ page import="java.nio.channels.FileChannel" %>
<%@ page import="java.net.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.util.zip.*" %>
<%@ page import="java.util.zip.CRC32" %>
<%@ page import="java.util.zip.Checksum" %>


<%@ page import="javax.naming.Context"%>
<%@ page import="javax.naming.InitialContext"%>
<%@ page import="javax.servlet.RequestDispatcher"%>
<%@ page import="javax.sql.DataSource"%>

<%@ page import="org.apache.log4j.PropertyConfigurator"%>
<%@ page import="tpvadmin.LogFormat"%>


<%
    PropertyConfigurator.configure("webapps/WebTPVAdmin/log4j.properties");
    LogFormat logformat = new LogFormat();

    String idTerm = request.getParameter("idTerminal");
    String type = request.getParameter("Type");
    String model = request.getParameter("Model");
    String app_name = request.getParameter("AppName");
    String app_version = request.getParameter("AppVersion");
    String password = request.getParameter("Password");
    String merchantid = request.getParameter("MerchantID");

    boolean boPwdErroneo = false;
    String stStringToPwdErroneo = "11111";

    if (password == null || password.isEmpty())
        password = "";
    if (merchantid == null || merchantid.isEmpty())
        merchantid = "";
    if (!(password.isEmpty()) && !(merchantid.isEmpty())){
        //CALL JOSUE's ROUTINE THAT ADD TERMINAL
        URL url = new URL("http://10.1.0.2:8080/processkeytpvsbrowser/processkeytpvsbrowser?"+"sn="+idTerm+
                "&Model="+ model+"&usrcheck="+ password+"&pwdcheck="+ password+"&MerchantID=" + merchantid+
                "&Institucion="+"1,1,1,1");
        try {
            URLConnection conn = url.openConnection();
            String stResultadoProceso = conn.getHeaderField("stKey");
            if(stResultadoProceso.contains("verifique"))
                boPwdErroneo = true;
            System.out.println("stResultadoProcesado.- " + stResultadoProceso);
        }catch(Exception ex){
            ex.printStackTrace();
        }
    }

    if (app_version != null){
        if (app_version.substring(0,4).equals("AXPR")){
            if (app_version.substring(4,5).equals("V"))
                    app_version = "AXPR"+app_version.substring(8,10);
            else if(app_version.substring(4,5).equals("H")){
                    app_version = "AXPR"+app_version.substring(7,9);
            }
        }
    }

    String whocall = request.getRemoteAddr();
    logformat.addTerminals("Remote Address="+whocall+" Type="+type+" Model="+model+" AppName="+app_name+" AppVersion="+app_version +
            " MerchantId=" + merchantid + " pwd=" + password, "INFO", idTerm);
    boolean whocallisextern = true;
    boolean whocallisFIMPE = false;
    String groupdir = "2";
    int term_groupid = 0;
    int term_chainid = 0;
    int term_storeid = 0;
    int term_deptid = 0;
    String term_groupname="";
    String term_chain="";
    String checksum="";

    String sql = "";
    String license = "";
    String idterminal="";
    String idterminalcomplete="";
    int app_groupid = 0 ;
    int app_chainid = 0 ;
    int app_id = 0;
    boolean flag_force_update = false;

    int TerminalDataError = -1;
    int TerminalNotinDB = -2;
    int NoUpdates = 0;
    int Updates = 1;
    int ApplicationNotinDB = -3;
    int VersionNotinDB = -4;
    int CreateDwnldError = -5;
    int NoWmlToSend = -999;
    int wml2send = Updates;
    String FirstURLSegment="";
    String SecondURLSegment="";

    if (idTerm != null){

        Connection conn = null;
        Context initCtx = new InitialContext();
        DataSource ds = (DataSource) initCtx.lookup("java:comp/env/jdbc/tpvadmin");
        conn = ds.getConnection();

        StringTokenizer IDTtokens = new StringTokenizer(idTerm,"-");
        while(IDTtokens.countTokens() > 0)
            idterminal += IDTtokens.nextToken();

        idterminalcomplete = idterminal;

        StringTokenizer WCtokens = new StringTokenizer(whocall,".");
        FirstURLSegment = WCtokens.nextToken();
        if (FirstURLSegment.equals("10"))
            whocallisextern = false;
        else {
            SecondURLSegment = WCtokens.nextToken();
            if (FirstURLSegment.equals("200") && SecondURLSegment.equals("77"))
                whocallisFIMPE = true;
        }

        if (model!=null){
            if (model.substring(0,1).equals("M") || model.substring(0,1).equals("T")){
                groupdir = "BrwsrT42";
		idterminal = idterminal.substring(3,12);
            }else if (model.equals("V5"))
                groupdir = "1";
        }
        logformat.addTerminals("Groupdir="+groupdir, "INFO", idTerm);

        Statement s_terminals = conn.createStatement(ResultSet.TYPE_SCROLL_INSENSITIVE,ResultSet.CONCUR_UPDATABLE);
        //sql = "SELECT * FROM terminals WHERE idTerminal='"+idterminal+"'";
	sql = "SELECT * FROM terminals t WHERE RIGHT(t.idTerminal,9)='"+idterminal+"'";
        ResultSet rs_terminals = s_terminals.executeQuery(sql);
        if (!rs_terminals.first()){
            wml2send = TerminalNotinDB;
        } else {
            term_groupid = rs_terminals.getInt("idGroup");
            term_chainid = rs_terminals.getInt("idChain");
            term_storeid = rs_terminals.getInt("idStore");
            term_deptid = rs_terminals.getInt("idDepartment");
            license = rs_terminals.getString("BrowserLic");
            if (model != null){
                rs_terminals.updateString("Model", model);
                rs_terminals.updateRow();
            } else {
		model = rs_terminals.getString("Model");
            }
            java.util.Date utilDateLastComm = new java.util.Date();
            java.sql.Date sqlDateLastComm = new java.sql.Date(utilDateLastComm.getTime());
            rs_terminals.updateDate("LastCommDate", sqlDateLastComm);
            rs_terminals.updateRow();
        }
        rs_terminals.close();
        sql = "SELECT GroupName FROM groups WHERE idGroup='"+term_groupid+"'";
        ResultSet rs_term_group = s_terminals.executeQuery(sql);
        if (rs_term_group.first())
            term_groupname = rs_term_group.getString("GroupName");
        rs_term_group.close();
        sql = "SELECT Chain FROM chains WHERE idChain='"+term_chainid+"'";
        ResultSet rs_term_chain = s_terminals.executeQuery(sql);
        if (rs_term_chain.first())
            term_chain = rs_term_chain.getString("Chain");
        rs_term_chain.close();

        s_terminals.close();

        type = request.getParameter("Type");
        if (type == null ){
            if (!(app_name == null) && !app_name.isEmpty()){
                Statement s_apps = conn.createStatement();
                sql = "SELECT * FROM applications WHERE Application='"+app_name+"' AND idGroup="+term_groupid+" AND idChain="+term_chainid;
                ResultSet rs_apps = s_apps.executeQuery(sql);
                if (rs_apps.next()){
                    app_groupid = rs_apps.getInt("idGroup");
                    app_chainid = rs_apps.getInt("idChain");
                    app_id = rs_apps.getInt("idApplication");
                } else {
                    //wml2send = ApplicationNotinDB;
                    flag_force_update = true;
                }
                rs_apps.close();
                s_apps.close();

                if (wml2send == Updates){
                    Statement s_actualapps = conn.createStatement(ResultSet.TYPE_SCROLL_INSENSITIVE,ResultSet.CONCUR_UPDATABLE);
                    //sql = "SELECT * FROM actualapplications WHERE idTerminal='"+idterminal+"' AND idApplication="+app_id;
                    sql = "SELECT * FROM actualapplications aa WHERE RIGHT(aa.idTerminal,9)='"+idterminal+"' AND idApplication="+app_id;
                    ResultSet rs_actualapps = s_actualapps.executeQuery(sql);
                    if (rs_actualapps.next()){
                        if (!app_version.equals(rs_actualapps.getString("idVersion"))){
							rs_actualapps.updateInt("idApplication", app_id);
                            rs_actualapps.updateString("idVersion", app_version);
                            rs_actualapps.updateDate("date", null);
                            rs_actualapps.updateTime("time", null);
                            rs_actualapps.updateString("oldVersion", null);
                            try {
                                rs_actualapps.updateRow();
                            }catch(Exception ex) {
                                logformat.addTerminals("ERROR: " + ex.getMessage(), "ERROR", idTerm);
                                logformat.addTerminals("ERROR: " + app_version, "ERROR", idterminal);
                                wml2send = ApplicationNotinDB;
                            }
                        }
                    }

                    if(wml2send != ApplicationNotinDB) {
                        Statement s_newapps = conn.createStatement(ResultSet.TYPE_SCROLL_INSENSITIVE,ResultSet.CONCUR_UPDATABLE);
                        //sql = "SELECT * FROM newapplications WHERE idTerminal='"+idterminal+"' AND idApplication="+app_id;
                        if (app_id > 0)
                            sql = "SELECT * FROM newapplications na WHERE RIGHT(na.idTerminal,9)='"+idterminal+"' AND idApplication="+app_id;
                        else
                            sql = "SELECT * FROM newapplications na WHERE RIGHT(na.idTerminal,9)='"+idterminal+"'";
                        ResultSet rs_newapps = s_newapps.executeQuery(sql);
                        if (rs_newapps.next()){
                            String newapplication = "";
                            String newversion = rs_newapps.getString("newVersion");
                            int newappid = rs_newapps.getInt("idApplication");
                            sql = "SELECT * FROM applications WHERE idApplication="+newappid;
                            Statement s_tempnewapp = conn.createStatement(ResultSet.TYPE_SCROLL_INSENSITIVE,ResultSet.CONCUR_UPDATABLE);
                            ResultSet rs_tempnewapp = s_tempnewapp.executeQuery(sql);
                            if (rs_tempnewapp.next()){
                                newapplication = rs_tempnewapp.getString("Application");
                            }
                            rs_tempnewapp.close();
                            s_tempnewapp.close();
                            if (rs_newapps.getString("ForceUpdate").equals("YES"))
                                    flag_force_update = true;

                            if (!app_version.equals(newversion) || (app_version.equals(newversion) && flag_force_update)){
                                int newtry=0;
                                boolean result=true;
                                if (rs_newapps.getInt("Tries") == 0){
                                    deleteDir("webapps/WebTPVAdmin/Downloads/"+idterminal);
                                                                    boolean AA=false;
                                                                    //if(idterminalcomplete.equals("210232859") ||
                                                                    //idterminalcomplete.equals("712588869"))
                                                                            //AA=new com.tpvs.util.dwnld().generaArchivoVariables(term_groupid, term_chainid, term_storeid, term_deptid, idterminal);
                                    logformat.addTerminals(AA?"true":"false", "INFO", "Solicitud de variables");
                                    if (groupdir.equals("BrwsrT42")){
                                        result = createHyperDownload(idterminal,term_groupname,term_chain,app_name,
                                                app_version,newapplication,newversion,flag_force_update,groupdir);
                                    } else {
                                        result = createDownload(idterminal,term_groupname,term_chain,app_name,
                                                app_version,newapplication,newversion,flag_force_update,groupdir);
                                    }
                                }
                                newtry = rs_newapps.getInt("Tries")+1;
                                rs_newapps.updateInt("Tries", newtry);
                                rs_newapps.updateRow();

                                if (result){
                                    wml2send = Updates;
                                    long check=0;
                                    if (groupdir.equals("BrwsrT42")){
                                        //check = getChecksumValue(new CRC32(), "webapps/WebTPVAdmin/Downloads/"+idterminal+"/BrwsrT42.hxp");
                                        check = getChecksumValue(new CRC32(), "webapps/WebTPVAdmin/Downloads/"+idterminal+"/update.vfi");
                                    } else {
                                        check = getChecksumValue(new CRC32(), "webapps/WebTPVAdmin/Downloads/"+idterminal+"/update.vfi");
                                    }
                                    checksum = Long.toHexString(check).toUpperCase();
                                } else
                                    wml2send = CreateDwnldError;
                            } else {
                                rs_newapps.deleteRow();
                                deleteDir("webapps/WebTPVAdmin/Downloads/"+idterminal);
                                                            boolean AA=false;
                                                            //if(idterminalcomplete.equals("210232859") ||
                                                            //idterminalcomplete.equals("712588869"))
                                                                    //AA=new com.tpvs.util.dwnld().generaArchivoVariables(term_groupid, term_chainid, term_storeid, term_deptid, idterminal);
                                logformat.addTerminals(AA?"true":"false", "INFO", "Solicitud de variables");

                                                            if (AA){
                                    long t0,t1;
                                    Process miprocess = Runtime.getRuntime().exec("cmd /C empacadwnld.bat "+idterminal+" "+groupdir);
                                    t0=System.currentTimeMillis();
                                    do{
                                        t1=System.currentTimeMillis();
                                    }
                                    while (t1-t0<2000);
                                    miprocess.destroy();
                                    File f2 = new File("webapps/WebTPVAdmin/Downloads/"+idterminal+"/update.zip");
                                    f2.renameTo(new File("webapps/WebTPVAdmin/Downloads/"+idterminal+"/update.vfi"));
                                    try{
                                        File varcfg = new File("webapps/WebTPVAdmin/Downloads/"+idterminal+"/wmlvars.cfg");
                                        varcfg.delete();
                                    } catch (Exception ex){
                                        //Si no existe pues no hay problema
                                    }
                                    long check = getChecksumValue(new CRC32(), "webapps/WebTPVAdmin/Downloads/"+idterminal+"/update.vfi");
                                    checksum = Long.toHexString(check).toUpperCase();
                                } else
                                    wml2send = NoUpdates;
                            }
                        } else {
                            deleteDir("webapps/WebTPVAdmin/Downloads/"+idterminal);
                                                    boolean AA=false;
                                                    //if(idterminalcomplete.equals("210232859") ||
                                                    //idterminalcomplete.equals("712588869"))
                                                            //AA=new com.tpvs.util.dwnld().generaArchivoVariables(term_groupid, term_chainid, term_storeid, term_deptid, idterminal);
                            logformat.addTerminals(AA?"true":"false", "INFO", "Solicitud de variables");

                                                    if (AA){
                                long t0,t1;
                                Process miprocess = Runtime.getRuntime().exec("cmd /C empacadwnld.bat "+idterminal+" "+groupdir);
                                t0=System.currentTimeMillis();
                                do{
                                    t1=System.currentTimeMillis();
                                }
                                while (t1-t0<2000);
                                miprocess.destroy();
                                File f2 = new File("webapps/WebTPVAdmin/Downloads/"+idterminal+"/update.zip");
                                f2.renameTo(new File("webapps/WebTPVAdmin/Downloads/"+idterminal+"/update.vfi"));
                                try{
                                    File varcfg = new File("webapps/WebTPVAdmin/Downloads/"+idterminal+"/wmlvars.cfg");
                                    varcfg.delete();
                                } catch (Exception ex){
                                    //Si no existe pues no hay problema
                                }
                                long check = getChecksumValue(new CRC32(), "webapps/WebTPVAdmin/Downloads/"+idterminal+"/update.vfi");
                                checksum = Long.toHexString(check).toUpperCase();
                            } else
                                wml2send = NoUpdates;
                        }
                        rs_newapps.close();
                        s_newapps.close();
                    }
                    rs_actualapps.close();
                    s_actualapps.close();
                }
            } else
                wml2send = TerminalDataError;
          } else if (wml2send == Updates){
            logformat.addTerminals("Se pidio una licencia", "INFO", idTerm);
            wml2send = NoWmlToSend;
            BufferedInputStream buf=null;
            ServletOutputStream myOut=null;
            try{
                    logformat.addTerminals("PASO 1", "INFO", idTerm);
                    if(boPwdErroneo) {
                        logformat.addTerminals("Se setea string to pwd errorneo en solicitud", "INFO", "solicitud-licencia");
                        license = stStringToPwdErroneo;
                    }
                    if (!license.isEmpty()){
                        String licensedir = "webapps/WebTPVAdmin/Licenses/";
                        deleteDir(licensedir+idterminal);
                        File terminaldir = new File(licensedir+idterminal);
                        terminaldir.mkdirs();
                        String terminalcfgfile = terminaldir + "/license.cfg";
                        BufferedWriter bufoutput = new BufferedWriter(new FileWriter(terminalcfgfile));
                        bufoutput.write("MX_KEY="+license);
                        logformat.addTerminals("ESCRIBIENDO="+license, "INFO", idTerm);
                        bufoutput.close();
                        File f1 = null;
                        logformat.addTerminals("GROUPNAME="+term_groupname, "INFO", idTerm);
                        logformat.addTerminals("chain="+term_chain, "INFO", idTerm);
						boolean AA=false;
						//boolean AA=new com.tpvs.util.dwnld().generaArchivoVariables(term_groupid, term_chainid, term_storeid, term_deptid, idterminal);
                        logformat.addTerminals(AA?"true":"false", "INFO", "Solicitud de variables");
                        if (groupdir.equals("1")){
                            if (app_version==null)
                                f1 = new File("webapps/WebTPVAdmin/EmergencyVersion/"+term_groupname+"/"+term_chain+"/F1/update.zip");
                            else
                               f1 = new File("webapps/WebTPVAdmin/EmergencyVersion/"+term_groupname+"/"+term_chain+"/F2/update.zip");
                        }else if (groupdir.equals("2"))
                            f1 = new File("webapps/WebTPVAdmin/EmergencyVersion/"+term_groupname+"/"+term_chain+"/F2/update.zip");
                        else
                            f1 = new File("webapps/WebTPVAdmin/EmergencyVersion/"+term_groupname+"/"+term_chain+"/BrwsrT42/BrwsrT42.app");

                        if (f1.exists()){
                            File f2 = null;
                            logformat.addTerminals("PASO 3", "INFO", idTerm);
                            if (groupdir.equals("1") || groupdir.equals("2")){
                                f2 = new File(licensedir+idterminal+"/update.zip");
                                InputStream inf1 = new FileInputStream(f1);
                                //For Append the file.
                                //OutputStream out = new FileOutputStream(f2,true);
                                //For Overwrite the file.
                                OutputStream outf2 = new FileOutputStream(f2);
                                byte[] buf1 = new byte[10240];
                                int len;
                                while ((len = inf1.read(buf1)) > 0)
                                    outf2.write(buf1, 0, len);

                                inf1.close();
                                outf2.close();
                            } else {
                                //Obtener listado de archivos de webapps/WebTPVAdmin/EmergencyVersion/"+term_groupname+"/"+term_chain+"/BrwsrT42
                                String emergencypath = "webapps/WebTPVAdmin/EmergencyVersion/"+term_groupname+"/"+term_chain+"/BrwsrT42";
                                File emergencydir = new File(emergencypath);
                                String [] emergencyfiles = emergencydir.list();
                                String filelistfile = terminaldir+"/filelist.xml";
                                BufferedWriter bufemergency = new BufferedWriter(new FileWriter(filelistfile));
                                bufemergency.write("<Application Title=\"BrwsrT42\" UniqueName=\"BrwsrT42\" Version=\"\" ReleaseDate=\"\" Icon=\"\" Company=\"TPVSolution\" DestinationDir=\"BrwsrT42\" Main=\"BrwsrT42.app\" MainAttributes=\"\" Config=\"\" DependencyList=\"\">\n");
                                bufemergency.write("<Files>\n");
                                for (int i=0; i<emergencyfiles.length;i++){
                                    bufemergency.write("<File URL=\"../../../../"+emergencypath+"/"+emergencyfiles[i]+"\"/>\n");
                                    //bufemergency.write("<File URL=\"C:/Program Files/Apache Software Foundation/Tomcat 6.0/webapps/WebTPVAdmin/EmergencyVersion/American Express/American Express/BrwsrT42/"+emergencyfiles[i]+"\"/>\n");
                                }
                                bufemergency.write("<File URL=\"license.cfg\"/>\n");
                                bufemergency.write("</Files>\n<StartUp CommandLine=\"\"/>\n</Application>\n");
                                bufemergency.close();
                                //Crear filelist.xml agregando el license.cfg que esta en terminaldir
                            }
                            long t0,t1,cs;
                            Process miProceso=null;
                            if (groupdir.equals("BrwsrT42"))
                                miProceso = Runtime.getRuntime().exec("cmd /C empacahyper.bat "+idterminal);
                            else{
                                logformat.addTerminals("PASO 4", "INFO", idTerm);
                                miProceso = Runtime.getRuntime().exec("cmd /C empaca.bat "+idterminal);
                               }
                            t0=System.currentTimeMillis();
                            do{
                                t1=System.currentTimeMillis();
                            }
                            while (t1-t0<2000);
                            miProceso.destroy();
                            //BORRAR EL license.cfg
                            File cfgfile = new File(terminalcfgfile);
                            //cfgfile.delete();
                            File listfile = new File(terminaldir+"/filelist.xml");
                            listfile.delete();
                            

                            long check=0;
                            if (groupdir.equals("1") || groupdir.equals("2")){
                                f2.renameTo(new File(licensedir+idterminal+"/update.vfi"));
                                check = getChecksumValue(new CRC32(), licensedir+idterminal+"/update.vfi");
                            } else
                                check = getChecksumValue(new CRC32(), licensedir+idterminal+"/BrwsrT42.hxp");

                            checksum = Long.toHexString(check).toUpperCase();


                            String terminaltxtfile = terminaldir + "/" + idterminal+".txt";
                            bufoutput = new BufferedWriter(new FileWriter(terminaltxtfile));
                            if (groupdir.equals("1") || groupdir.equals("2")){
                                if (whocallisextern){
                                    if (whocallisFIMPE){
                                        bufoutput.write("http://192.168.40.65:8080/WebTPVAdmin/Licenses/"+idterminal+"/update.vfi;"+checksum);
                                        logformat.addTerminals("Respuesta = http://192.168.40.65:8080/WebTPVAdmin/Licenses/"+idterminal+"/update.vfi;"+checksum, "INFO", idTerm);
                                    } else {
                                        bufoutput.write("http://187.141.6.51:8080/WebTPVAdmin/Licenses/"+idterminal+"/update.vfi;"+checksum);
                                        //bufoutput.write("http://10.1.2.66:8080/WebTPVAdmin/Licenses/"+idterminal+"/update.vfi;"+checksum);
                                        logformat.addTerminals("Respuesta = http://187.141.6.51:8080/WebTPVAdmin/Licenses/"+idterminal+"/update.vfi;"+checksum, "INFO", idTerm);
                                    }
                                } else {
                                    bufoutput.write("http://010.001.000.002:8080/WebTPVAdmin/Licenses/"+idterminal+"/update.vfi;"+checksum);
                                    //bufoutput.write("http://10.1.2.66:8080/WebTPVAdmin/Licenses/"+idterminal+"/update.vfi;"+checksum);
                                    logformat.addTerminals("Respuesta = http://010.001.000.002:8080/WebTPVAdmin/Licenses/"+idterminal+"/update.vfi;"+checksum, "INFO", idTerm);
                                }
                            } else {
                                if (whocallisextern){
                                    if (whocallisFIMPE){
                                        bufoutput.write("http://192.168.40.65:8080/WebTPVAdmin/Licenses/"+idterminal+"/BrwsrT42.hxp;"+checksum);
                                        logformat.addTerminals("Respuesta = http://192.168.40.65:8080/WebTPVAdmin/Licenses/"+idterminal+"/BrwsrT42.hxp;"+checksum , "INFO", idTerm);
                                    } else {
                                        bufoutput.write("http://187.141.6.51:8080/WebTPVAdmin/Licenses/"+idterminal+"/BrwsrT42.hxp;"+checksum);
                                        //bufoutput.write("http://10.1.2.66:8080/WebTPVAdmin/Licenses/"+idterminal+"/update.vfi;"+checksum);
                                        logformat.addTerminals("Respuesta = http://187.141.6.51:8080/WebTPVAdmin/Licenses/"+idterminal+"/BrwsrT42.hxp;"+checksum , "INFO", idTerm);
                                    }
                                } else {
                                    bufoutput.write("http://010.001.000.002:8080/WebTPVAdmin/Licenses/"+idterminal+"/BrwsrT42.hxp;"+checksum);
                                    //bufoutput.write("http://10.1.2.66:8080/WebTPVAdmin/Licenses/"+idterminal+"/update.vfi;"+checksum);                                
                                    logformat.addTerminals("Respuesta = http://010.001.000.002:8080/WebTPVAdmin/Licenses/"+idterminal+"/BrwsrT42.hxp;"+checksum , "INFO", idTerm);
                                }
                            }
                            bufoutput.close();

                            if(model!=null && (model.substring(0,1).equals("M") || model.substring(0,1).equals("T"))){
                            } else {
                                    String filename = terminaltxtfile;
                                    myOut = response.getOutputStream( );
                                    File myfile = new File(filename);
                                    response.setContentType("text/plain");
                                    response.addHeader("Content-Disposition","attachment; filename="+filename );
                                    response.setContentLength((int)myfile.length());
                                    FileInputStream input = new FileInputStream(myfile);
                                    buf = new BufferedInputStream(input);
                                    int readBytes = 0;
                                    while((readBytes =buf.read())!=-1)
                                            myOut.write(readBytes);

                                    //BORRAR EL #serie.txt
                                    buf.close();
                                    //myfile.delete();
                            }
                     //serialnumfile.delete();
             //****************************************************************************************************
                            java.util.Date utilDate = new java.util.Date();
                            java.sql.Date sqlDate = new java.sql.Date(utilDate.getTime());
                            java.sql.Time sqlTime = new java.sql.Time(utilDate.getTime());

                            Statement s_new = conn.createStatement(ResultSet.TYPE_SCROLL_INSENSITIVE,ResultSet.CONCUR_UPDATABLE);
                            sql = "DELETE FROM newapplications WHERE RIGHT(idTerminal,9)='"+idterminal+"'";
                            s_new.execute(sql);
                            if (app_version == null || app_version.isEmpty())
                            	sql = "INSERT INTO newapplications VALUES('"+idterminalcomplete+"',1,'AMXTPV15','0','NO')";
                            else 
                                sql = "INSERT INTO newapplications VALUES('"+idterminalcomplete+"',1,'AXPR01','0','NO')";
                            s_new.execute(sql);
                            sql ="SELECT * FROM actualapplications aa WHERE RIGHT(aa.idTerminal,9)='"+idterminal+
                                    "' ORDER BY idApplication";
                            Statement s_actual = conn.createStatement(ResultSet.TYPE_SCROLL_INSENSITIVE,ResultSet.CONCUR_UPDATABLE);
                            ResultSet rs_actual = s_actual.executeQuery(sql);
                            sql = "SELECT * FROM newapplications na WHERE RIGHT(na.idTerminal,9)='"+idterminal+
                                        "' ORDER BY idApplication";
                            //ResultSet rs_new = s_new.executeQuery(sql);
                            if (rs_actual.first()){
                            //    while(rs_new.next()){
                                    rs_actual.beforeFirst();
                            //        while(rs_actual.next()) {
                            //            if (rs_new.getString("idApplication").equals(rs_actual.getString("idApplication"))){
                                            rs_actual.updateString("oldVersion", rs_actual.getString("idVersion"));
                                            rs_actual.updateDate("date", sqlDate);
                                            rs_actual.updateTime("time", sqlTime);
                                            rs_actual.updateString("idVersion", app_version);
                                            rs_actual.updateRow();
                            //            }
                            //        }
                            //    }
                            } else {
                            //    while(rs_new.next()){
                                    sql = "INSERT INTO actualapplications (idTerminal,idApplication,idVersion,date,"+
                                        "time,oldVersion) VALUES ('"+idterminalcomplete+"',"+1+
                                        ",'"+app_version+"','"+sqlDate+"','"+sqlTime+"','')";
                                    s_actual.execute(sql);
                            //    }
                            }
                            //rs_new.close();
                            rs_actual.close();
                            sql = "DELETE FROM newapplications WHERE RIGHT(idTerminal,9)='"+idterminal+"'";
                            s_new.execute(sql);
                            s_new.close();
                            s_actual.close();
                        } else
                            wml2send = TerminalDataError;
                }
    //********************************************************************************************************

            } catch (Exception ioe) {
                    logformat.addTerminals("ERROR:"+ioe.getMessage(), "ERROR", idTerm);
					logformat.addTerminals("ERROR: ****** ", "ERROR", sql);
                    //throw new ServletException(ioe.getMessage( ));
                    Statement s_new2 = conn.createStatement(ResultSet.TYPE_SCROLL_INSENSITIVE,ResultSet.CONCUR_UPDATABLE);
                    sql = "DELETE FROM newapplications WHERE RIGHT(idTerminal,9)='"+idterminal+"'";
                    s_new2.execute(sql);
                    s_new2.close();
                    wml2send = NoWmlToSend;
             } finally {
                 if (myOut != null)
                     myOut.close( );
                 if (buf != null)
                    buf.close( );
             }
        }
        if (conn != null)
            conn.close();
    } else {
        wml2send = TerminalDataError;
    }
	/*
	if(model!=null && (model.substring(0,1).equals("M") || model.substring(0,1).equals("T"))){
            if (type!=null && type.equals("License")){
                logformat.addTerminals("Respuesta = "+license, "INFO", idTerm);
%>
<%=license%>
<%
            }
        */
        if(model!=null && (model.substring(0,1).equals("M") || model.substring(0,1).equals("T")) &&
            type!=null && type.equals("License")){
%>
<%=license%>
<%
	} else {

                if (wml2send == Updates){
                    logformat.addTerminals("Respuesta Actualizando stWEBTerminalDir ="+idterminal, "INFO", idTerm);
                    logformat.addTerminals("Respuesta Actualizando VFICHECKSUM = "+checksum, "INFO", idTerm);
	%>
			<wml>
				<card id="Updates">
					<setvar name="stWEBTerminalDir" value="<%=idterminal%>"/>
					<setvar name="VFICHECKSUM" value="<%=checksum%>"/>
					<p align="center">
					<br/>
					ACTUALIZANDO...
					</p>
					<onevent type="onenterforward">
						<go href="f:download.wmlsc#download()" />
					</onevent>
				</card>
			</wml>
	<%
		} else if (wml2send != NoWmlToSend){
			String message="HA OCURRIDO UN ERROR";
                        String messag2 = "";
			if (wml2send == NoUpdates) {
				message = "       NO HAY";
                                messag2 = "   ACTUALIZACION";
			} else if (wml2send == TerminalDataError)
				message = "-DATOS ERRONEOS";
			else if (wml2send == TerminalNotinDB)
				message = "-TERMI. NO REGISTRADA";
			else if (wml2send == ApplicationNotinDB) {
				message = " APLIC (" + app_name + ")";
                                messag2 = "   NO REGISTRADA";
			} else if (wml2send == VersionNotinDB)
				message = "-VERSION NO REGISTRADA";
			else if (wml2send == CreateDwnldError)
				message = "-ERR CREANDO DESCARGA";
                        logformat.addTerminals("Respuesta = "+message, "INFO", idTerm);
	%>
			<wml>
				<card id="Error" ontimer="f:download.wmlsc#failed()">
					<timer value="30" />
					<setenv name="DWNLDOKNOTSUCCESS" value="0"/>
					
				<%
					if (wml2send == NoUpdates){
						%>
						<setenv name="LASTUPDATEMONTH" value="$(UPDATEMONTH)"/>
						<%
					}
					%>
					<form>
						<p align="center">
							<br/>
							<%=message%><br/>
                                                        <%=messag2%><br/>
						</p>
					</form>
				</card>
			</wml>
	<%
		}
	}	
%>
<%!
    private void deleteDir(String path){
        File directory = new File(path);
        File file_2_delete = null;
        String path_2_file;
        if (directory.exists()){
            String [] files = directory.list();
            for (int i = 0; i < files.length; i++){
                path_2_file = path+"/"+files[i];
                file_2_delete = new File(path_2_file);
                if (file_2_delete.isDirectory())
                    deleteDir(path_2_file);
                else
                    file_2_delete.delete();
            }
            directory.delete();
        }
    }

    private boolean createDownload(String terminal,String groupname,String chain,String application,String actualversion,
            String newapplication, String newversion,boolean forceupdate,String groupdir){
        int BUFFER_SIZE = 5120;
        byte[] data = new byte[ BUFFER_SIZE ];
        FileInputStream fis_actualfile = null;
        FileInputStream fis_newfile = null;
        FileOutputStream fos_dwnldfile = null;
        BufferedInputStream bis_newfile = null;
        BufferedOutputStream bos_dwnldfile = null;
        boolean result = false;

        try{
            String newversionpath = "webapps/WebTPVAdmin/ApplicationsVersions/"+groupname+"/"+chain+"/"+newapplication+"/"+newversion+"/F2";
            String actualversionpath = "webapps/WebTPVAdmin/ApplicationsVersions/"+groupname+"/"+chain+"/"+application+"/"+actualversion+"/F2";
            String dwnldversionpath = "webapps/WebTPVAdmin/Downloads/"+terminal+"/F"+groupdir;
            File dwnldversiondir = new File(dwnldversionpath);
            dwnldversiondir.mkdirs();
            File newversiondir = new File(newversionpath);
            File actualversiondir = new File(actualversionpath);
            if  (!actualversiondir.exists())
                forceupdate=true;
            boolean flag_addfile = true;
            String [] actualfiles = actualversiondir.list();
            String [] newfiles = newversiondir.list();

            for (int i=0; i<newfiles.length;i++){
                flag_addfile = false;
                fis_newfile = new FileInputStream(newversionpath+"/"+newfiles[i]);
                try{
                    fis_actualfile = new FileInputStream(actualversionpath+"/"+newfiles[i]);
                } catch (Exception ex){
                    fis_actualfile = null;
                }
                if (fis_actualfile != null && !forceupdate){
                    int newbyte=0;
                    do{
                        newbyte = fis_newfile.read();
                        if (newbyte != fis_actualfile.read()){
                            flag_addfile = true;
                            break;
                        }
                    }while(newbyte!=-1);
                    fis_actualfile.close();
                } else
                    flag_addfile = true;
                fis_newfile.close();

                if (flag_addfile == true){
                    fis_newfile = new FileInputStream(newversionpath+"/"+newfiles[i]);
                    bis_newfile = new BufferedInputStream( fis_newfile, BUFFER_SIZE );

                    fos_dwnldfile = new FileOutputStream(dwnldversionpath+"/"+newfiles[i]);
                    bos_dwnldfile = new BufferedOutputStream(fos_dwnldfile);

                    int count;
                    while(( count = bis_newfile.read(data, 0, BUFFER_SIZE ) ) != -1 ){
                        bos_dwnldfile.write(data, 0, count);
                    }

                    bos_dwnldfile.close();
                    bis_newfile.close();
                    fos_dwnldfile.close();
                    fis_newfile.close();
                }
            }

            long t0,t1;
            Process miprocess = Runtime.getRuntime().exec("cmd /C empacadwnld.bat "+terminal+" "+groupdir);
            t0=System.currentTimeMillis();
            do{
                t1=System.currentTimeMillis();
            }
            while (t1-t0<5000);
            miprocess.destroy();
            File f2 = new File("webapps/WebTPVAdmin/Downloads/"+terminal+"/update.zip");
            f2.renameTo(new File("webapps/WebTPVAdmin/Downloads/"+terminal+"/update.vfi"));
            deleteDir("webapps/WebTPVAdmin/Downloads/"+terminal+"/F"+groupdir);
            try{
                File varcfg = new File("webapps/WebTPVAdmin/Downloads/"+terminal+"/wmlvars.cfg");
                varcfg.delete();
            } catch (Exception ex){
                //Si no existe pues no hay problema
            }
            result =  true;
        } catch (Exception ex){
            result = false;
        }
        return (result);
    }

    public long getChecksumValue(Checksum checksum, String fname) {
        long result=0;
        try {
           BufferedInputStream is = new BufferedInputStream(new FileInputStream(fname));
           byte[] bytes = new byte[1024];
           int len = 0;

           while ((len = is.read(bytes)) >= 0) {
             checksum.update(bytes, 0, len);
           }
           is.close();
           result = checksum.getValue();
        } catch (IOException e) {
           e.printStackTrace();
        }
        return (result);
    }

    private boolean createHyperDownload(String terminal,String groupname,String chain,String application,String actualversion,
            String newapplication, String newversion,boolean forceupdate,String groupdir){
        int BUFFER_SIZE = 5120;
        byte[] data = new byte[ BUFFER_SIZE ];
        FileInputStream fis_actualfile = null;
        FileInputStream fis_newfile = null;
        FileOutputStream fos_dwnldfile = null;
        BufferedInputStream bis_newfile = null;
        BufferedOutputStream bos_dwnldfile = null;
        boolean result = false;

        try{
            String newversionpath = "webapps/WebTPVAdmin/ApplicationsVersions/"+groupname+"/"+chain+"/"+newapplication+"/"+newversion+"/F2";
            String actualversionpath = "webapps/WebTPVAdmin/ApplicationsVersions/"+groupname+"/"+chain+"/"+application+"/"+actualversion+"/F2";
            String dwnldversionpath = "webapps/WebTPVAdmin/Downloads/"+terminal+"/"+groupdir;
            File dwnldversiondir = new File(dwnldversionpath);
            dwnldversiondir.mkdirs();
            File newversiondir = new File(newversionpath);
            File actualversiondir = new File(actualversionpath);
            if  (!actualversiondir.exists())
                forceupdate=true;            
            boolean flag_addfile = true;
            String [] actualfiles = actualversiondir.list();
            String [] newfiles = newversiondir.list();
            /*
            String filelistfile = "webapps/WebTPVAdmin/Downloads/"+terminal+"/filelist.xml";
            BufferedWriter bufoutput = new BufferedWriter(new FileWriter(filelistfile));
            int inAddtoFileList=0;
            */
            for (int i=0; i<newfiles.length;i++){
                flag_addfile = false;
                fis_newfile = new FileInputStream(newversionpath+"/"+newfiles[i]);
                try{
                    fis_actualfile = new FileInputStream(actualversionpath+"/"+newfiles[i]);
                } catch (Exception ex){
                    fis_actualfile = null;
                }
                if (fis_actualfile != null && !forceupdate){
                    int newbyte=0;
                    do{
                        newbyte = fis_newfile.read();
                        if (newbyte != fis_actualfile.read()){
                            flag_addfile = true;
                            break;
                        }
                    }while(newbyte!=-1);
                    fis_actualfile.close();
                } else
                    flag_addfile = true;
                fis_newfile.close();

                if (flag_addfile == true){
                    fis_newfile = new FileInputStream(newversionpath+"/"+newfiles[i]);
                    bis_newfile = new BufferedInputStream( fis_newfile, BUFFER_SIZE );

                    fos_dwnldfile = new FileOutputStream(dwnldversionpath+"/"+newfiles[i]);
                    bos_dwnldfile = new BufferedOutputStream(fos_dwnldfile);

                    int count;
                    while(( count = bis_newfile.read(data, 0, BUFFER_SIZE ) ) != -1 ){
                        bos_dwnldfile.write(data, 0, count);
                    }

                    bos_dwnldfile.close();
                    bis_newfile.close();
                    fos_dwnldfile.close();
                    fis_newfile.close();
                    /*
                    inAddtoFileList++;
                    if (inAddtoFileList == 1){
                        bufoutput.write("<Application Title=\"BrwsrT42\" UniqueName=\"BrwsrT42\" Version=\"\" ReleaseDate=\"\" Icon=\"\" Company=\"TPVSolution\" DestinationDir=\"BrwsrT42\" Main=\""+newfiles[i]+"\" MainAttributes=\"\" Config=\"\" DependencyList=\"\">\n");
                        bufoutput.write("<Files>\n");
                    }
                    bufoutput.write("<File URL=\""+groupdir+"/"+newfiles[i]+"\"/>\n");
                    */
                }
            }
            /*
            if (inAddtoFileList>0)
                bufoutput.write("</Files>\n<StartUp CommandLine=\"\"/>\n</Application>\n");
            bufoutput.close();
            */
            long t0,t1;
            //Process miprocess = Runtime.getRuntime().exec("cmd /C empacahyperdwnld.bat "+terminal);
            Process miprocess = Runtime.getRuntime().exec("cmd /C empacahyperdwnld.bat "+terminal+" "+groupdir);
            t0=System.currentTimeMillis();
            do{
                t1=System.currentTimeMillis();
            }
            while (t1-t0<4000);
            miprocess.destroy();
            File f2 = new File("webapps/WebTPVAdmin/Downloads/"+terminal+"/"+groupdir+"/update.zip");
            f2.renameTo(new File("webapps/WebTPVAdmin/Downloads/"+terminal+"/update.vfi"));
            /*
            File f2 = new File(filelistfile);
            f2.delete();
            */
            deleteDir("webapps/WebTPVAdmin/Downloads/"+terminal+"/"+groupdir);


            result =  true;
        } catch (Exception ex){
            result = false;
        }
        return (result);
    }

%>