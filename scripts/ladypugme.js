// Commands:
//   hubot ladypug me - Disturbing...
//

module.exports = function (robot) {
    robot.respond(/ladypug me/i, function (msg) {
        msg.send('http://i.imgur.com/ko3Urfl.jpg');
    });
};
