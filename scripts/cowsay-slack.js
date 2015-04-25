// Commands:
//   hubot cowsay <phrase> - default cow says phrase
//   hubot cowsay cows - list available cows
//   hubot cowsay /<cow>/<eyes>/<tongue> <phrase> - say phrase using cow having eyes and tongue
//

module.exports = function (robot) {
    robot.respond(/cowsay (.+)/i, function (msg) {
        var say = msg.match[1].trim();
        var callback;

        if (say === 'cows') {
            callback = function (err, res, body) {
                cows = body.split('\n').join(', ');
                msg.send(cows);
            };

            msg.http('http://cowsay.rest/api/cows')
                .header('accept', 'text/plain')
                .get()(callback);
        } else {
            var cow = 'cow';
            var eyes = 'oo';
            var tongue = '';

            var optional = say.match(/\/(.*)\/(.*)\/(.*) (.+)/);
            if (optional) {
                cow = optional[1];
                eyes = optional[2] || eyes;
                tongue = optional[3] || tongue;
                say = optional[4];
            }

            callback = function (err, res, body) {
                msg.send('```' + body + '```');
            };
            msg.http('http://cowsay.rest/api/say/' + cow + '/' + eyes + '/' + tongue)
                .header('accept', 'text/plain')
                .header('content-type', 'text/plain')
                .post(say)(callback);
        }
    });
};
