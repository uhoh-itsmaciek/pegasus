package org.postgresql.db {
    import org.postgresql.util.DateFormatter;
    import org.postgresql.codec.encode.BoolIn;
    import org.postgresql.codec.encode.TimestamptzIn;
    import org.postgresql.codec.encode.Float8In;
    import org.postgresql.codec.encode.TextIn;
    import org.postgresql.codec.encode.Int4In;
    import org.postgresql.Oid;
    import org.postgresql.PgURL;
    import org.postgresql.codec.CodecFactory;
    import org.postgresql.codec.decode.DateOut;
    import org.postgresql.codec.decode.FloatOut;
    import org.postgresql.codec.decode.IntOut;
    import org.postgresql.codec.decode.TextOut;
    import org.postgresql.febe.FEBEConnection;
    import org.postgresql.febe.MessageStreamFactory;
    import org.postgresql.io.SocketDataStreamFactory;

    /**
     * A simple wiring of all the pegasus pieces into a single, simple interface.
     *
     * This essentially configures a default set of options for pegasus, including CodecFactory
     * and various other factories. The other pegasus classes are designed with reusability
     * and flexibility in mind; ConnectionFactory provides a facade to all that which is primarily
     * concerned with simplicity.
     */
    public class ConnectionFactory {

        private var _codecFactory:CodecFactory;

        public function ConnectionFactory() {
            _codecFactory = new CodecFactory();

            _codecFactory.registerDecoder(Oid.INT2, new IntOut());
            _codecFactory.registerDecoder(Oid.INT4, new IntOut());
            _codecFactory.registerDecoder(Oid.FLOAT4, new FloatOut());
            _codecFactory.registerDecoder(Oid.FLOAT8, new FloatOut());
            _codecFactory.registerDecoder(Oid.TIMESTAMP, new DateOut());
            _codecFactory.registerDecoder(Oid.TIMESTAMPTZ, new DateOut());
            _codecFactory.registerDecoder(Oid.BPCHAR, new TextOut());
            _codecFactory.registerDecoder(Oid.VARCHAR, new TextOut());
            _codecFactory.registerDecoder(Oid.CHAR, new TextOut());
            _codecFactory.registerDecoder(Oid.TEXT, new TextOut());

            _codecFactory.registerEncoder(int, new Int4In());
            _codecFactory.registerEncoder(String, new TextIn());
            _codecFactory.registerEncoder(Number, new Float8In());
            _codecFactory.registerEncoder(Boolean, new BoolIn());
            _codecFactory.registerEncoder(Date, new TimestamptzIn(new DateFormatter(), true));

            _codecFactory.registerDefaultDecoder(new TextOut());
        }

        public function createConnection(url:String, user:String, password:String):IConnection {
            var pegasusUrl:PgURL = new PgURL(url);

            var brokerFactory:MessageStreamFactory =
                new MessageStreamFactory(
                    new SocketDataStreamFactory(pegasusUrl.host, pegasusUrl.port));
            var params:Object = {};
            for (var key:String in pegasusUrl.parameters) {
                params[key] = pegasusUrl.parameters[key];
            }
            params.user = user;
            params.database = pegasusUrl.db;
            var febeConn:FEBEConnection = new FEBEConnection(params, password, brokerFactory);
            var conn:Connection = new Connection(febeConn, new QueryHandlerFactory(_codecFactory));
            return conn;
        }
    }
}