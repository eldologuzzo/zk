<%@page import="com.tpvs.util.MyProperties"%>											 
<%@ page import="java.sql.*" %>
<%@ page import="java.io.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.util.Calendar" %>
<%@ page import="java.nio.channels.FileChannel" %>


<%@ page import="javax.naming.Context"%>
<%@ page import="javax.naming.InitialContext"%>
<%@ page import="javax.servlet.RequestDispatcher"%>
<%@ page import="javax.sql.DataSource"%>

<%
        try{
            java.util.Date utilDate = new java.util.Date();
            java.sql.Date sqlDate = new java.sql.Date(utilDate.getTime());
            java.sql.Time sqlTime = new java.sql.Time(utilDate.getTime());
            String idTerm = request.getParameter("idTerminal");
            String idterminal="";
            if (idTerm != null){
                StringTokenizer IDTtokens = new StringTokenizer(idTerm,"-");
                while(IDTtokens.countTokens() > 0)
                    idterminal += IDTtokens.nextToken();
            }
            Connection conn = null;
            Context initCtx = new InitialContext();
            DataSource ds = (DataSource) initCtx.lookup("java:comp/env/jdbc/tpvadmin");
            conn = ds.getConnection();
            
            //Improper Neutralization of Special Elements used in an SQL Command ('SQL Injection') (CWEID 89) 
            //Statement s_new = conn.createStatement();
            //Statement s_actual = conn.createStatement(ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_UPDATABLE);
            
            //String sql ="SELECT * FROM actualapplications WHERE idTerminal='"+idterminal+ "' ORDER BY idApplication";
            //ResultSet rs_actual = s_actual.executeQuery(sql);
            
            String sql ="SELECT * FROM actualapplications WHERE idTerminal=? ORDER BY idApplication";
            PreparedStatement s_actual = conn.prepareStatement(sql,ResultSet.TYPE_SCROLL_INSENSITIVE,ResultSet.CONCUR_UPDATABLE);
            s_actual.setString(1,idterminal);            
            ResultSet rs_actual = s_actual.executeQuery();

            //sql = "SELECT * FROM newapplications WHERE idTerminal='"+idterminal+ "' ORDER BY idApplication";
            //ResultSet rs_new = s_new.executeQuery(sql);
            
            sql = "SELECT * FROM newapplications WHERE idTerminal=? ORDER BY idApplication";
            PreparedStatement s_new = conn.prepareStatement(sql);
            s_new.setString(1,idterminal);
            ResultSet rs_new = s_new.executeQuery();            
            
            if (rs_actual.first()){
                while(rs_new.next()){
                    rs_actual.beforeFirst();
                    while(rs_actual.next()) {
                        if (rs_new.getString("idApplication").equals(rs_actual.getString("idApplication"))){
                            rs_actual.updateString("oldVersion", rs_actual.getString("idVersion"));
                            rs_actual.updateDate("date", sqlDate);
                            rs_actual.updateTime("time", sqlTime);
                            rs_actual.updateString("idVersion", rs_new.getString("newVersion"));
                            rs_actual.updateRow();
                        }
                    }
                }
            } else {
                while(rs_new.next()){

                    //sql = "INSERT INTO actualapplications (idTerminal,idApplication,idVersion,date,"+"time,oldVersion) VALUES ('"+idterminal+"','"+rs_new.getString("idApplication")+"','"+rs_new.getString("newVersion")+"','"+sqlDate+"','"+sqlTime+"','')";
                    //s_actual.execute(sql);
                    
                    sql = "INSERT INTO actualapplications (idTerminal,idApplication,idVersion,date,time,oldVersion) VALUES (?,?,?,?,?,?)"; 
                    s_actual = conn.prepareStatement(sql,ResultSet.TYPE_SCROLL_INSENSITIVE,ResultSet.CONCUR_UPDATABLE);
                    s_actual.setString(1, idterminal);
                    //s_actual.setString(2,rs_new.getString("idApplication"));
                    s_actual.setInt(2,rs_new.getInt("idApplication"));
                    s_actual.setString(3,rs_new.getString("newVersion") );
                    s_actual.setDate(4, sqlDate);
                    s_actual.setTime(5, sqlTime);
                    s_actual.setString(6, "");
                    s_actual.execute();
                }
            }
            rs_new.close();
            rs_actual.close();
            //sql = "DELETE FROM newapplications WHERE idTerminal='"+idterminal+"'";
            //s_new.execute(sql);
            sql = "DELETE FROM newapplications WHERE idTerminal=?";
            s_new = conn.prepareStatement(sql);
            s_new.setString(1, idterminal);
            s_new.execute();            
            s_new.close();
            s_actual.close();
            //File directory = new File("webapps/WebTPVAdmin/Downloads/"+idterminal);
            //File file = new File("webapps/WebTPVAdmin/Downloads/"+idterminal+"/update.vfi");
            //file.delete();
            //directory.delete();
            deleteDir("webapps/WebTPVAdmin/Downloads/"+idterminal);
                %>
                    <wml>
                        <card id="successDL" ontimer="f:download.wmlsc#unzipFile()">
                            <timer value="30"/>
                             <setvar name="MX_NOCMSRVSTATUS" value="0"/>
                             <setenv name="LASTUPDATEMONTH" value="$(UPDATEMONTH)"/>
							 <setenv name="DWNLDOKNOTSUCCESS" value="0"/>
                                <p align="center">
                                        ACTUALIZACION<br/>
                                        DESCARGA EXITOSA<br/>
                                </p>
                        </card>
                    </wml>
<%
            } catch (Exception ex){
                %>
                <wml>
                    <card id="servererror" ontimer="f:download.wmlsc#failed()">
                        <timer value="30" />
                        <p align="center">
                            <br/>
                            ERROR EN EL SERVIDOR
                        </p>
                    </card>
                </wml>
                <%
            }
%>
<%!
    private void deleteDir(String path){
    //External Control of File Name or Path (CWE ID 73)
    //MyProperties.setPropiedad("Rutajsp",path );
    //path = MyProperties.getPropiedad("Rutajsp");
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
%>