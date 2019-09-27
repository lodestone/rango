import opal from 'opal.rb';
opal();
Opal.load('opal');
import native from 'native.rb'
native();
Opal.load('native');
import promise from 'promise.rb'
promise();
Opal.load('promise');

exports.Opal = Opal;
