package gd;

import java.io.PrintStream;
import java.io.IOException;
import java.sql.*;
import java.util.HashMap;
import java.util.Map;

public abstract class Base {
  PrintStream o;
  Connection con;
  Map names;
  Map users;

  public Base(){
    o = System.out;
    names = new HashMap();
    users = new HashMap();
  }

	public void doProc(String url, String user, String pass) throws Exception{
    try{
      Class.forName("org.gjt.mm.mysql.Driver").newInstance();
      con = DriverManager.getConnection(url + "?useUnicode=true&characterEncoding=UTF-8",user,pass);
      
      o.println("接続成功!!");
      
      doQuery(con);
      
    }catch(SQLException e){
      System.err.println("接続失敗です\n理由: " + e.toString());
      e.printStackTrace();
	  throw e;
    }catch(Exception e){
      e.printStackTrace();
	  throw e;
	}finally{
      try{
        if (con != null){
          con.close();
          con = null;
          o.println("接続開放!!");
        }
      }catch(Exception e){
        e.printStackTrace();
      }
    }
  }
  
  private void doQuery(Connection con) throws SQLException{
    Statement stmt = null;
    ResultSet res = null;
    try {
      String sql = getQueryString();
      stmt = con.createStatement();
      res = stmt.executeQuery(sql);
      
      procResultSet(res);
      
    }finally{
      // 資源の解放
      if (res != null) res.close();
      if (stmt != null) stmt.close();
    }
  }
  
  public abstract String getQueryString();
  
  public abstract void procResultSet(ResultSet res) throws SQLException;
  
  public abstract void writeExcel(String fileName) throws IOException;
}
