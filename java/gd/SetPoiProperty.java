package gd;

public class SetPoiProperty {

    public static void main(String[] args) {

        try {
            // 引数が足りない場合、例外を投げて終了
            if(args.length < 5) throw new Exception("usage args.. [url] [user] [pass] [ids]");

            // 引数を変数に格納
            String url = args[0];
            String user = args[1];
            String pass = args[2];
            String ids = args[3];
            String root = args[4];

            SetPoiFile obj = new SetPoiFile(ids, root);
            obj.doProc(url, user, pass);

        }catch(Exception e){
            e.printStackTrace();
        }

    }
}
