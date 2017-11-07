const Helper = require('hubot-test-helper');

const helper = new Helper('./../src/hubot-lunch.coffee');

const co     = require('co');
const expect = require('chai').expect;

describe('hello-world', function() {
    beforeEach(function() {
        this.room = helper.createRoom();
    });
    afterEach(function() {
        this.room.destroy();
    });

    context('user orders for himself', function() {
        beforeEach(function() {
            return co(function*() {
                yield this.room.user.say('lorem', '@hubot i want Tofu Thai-Curry');
            }.bind(this));
        });

        it('should reply to user', function() {
            expect(this.room.messages).to.eql([
                ['lorem', '@hubot i want Tofu Thai-Curry'],
                ['hubot', 'ok, added Tofu Thai-Curry to your order.']
            ]);
        });
    });

    context('user orders for another person', function() {
        beforeEach(function() {
            return co(function*() {
                yield this.room.user.say('lorem', '@hubot @ipsum wants Tofu Zitronengras');
                yield this.room.user.say('lorem', '@hubot lunch orders');
            }.bind(this));
        });

        it('should reply to user', function() {
            expect(this.room.messages).to.eql([
                ['lorem', '@hubot @ipsum wants Tofu Zitronengras'],
                ['hubot', 'ok, added Tofu Zitronengras to @ipsum order.'],
                ['lorem', '@hubot lunch orders'],
                ['hubot', 'ipsum: Tofu Zitronengras']
            ]);
        });
    });
});