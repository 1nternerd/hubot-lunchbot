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

    context('user wants to see a list of restaurants', function() {
        beforeEach(function() {
            return co(function*() {
                yield this.room.user.say('lorem', '@hubot restaurants');
            }.bind(this));
        });

        it('should list restaurants', function() {
            expect(this.room.messages[0]).to.eql(['lorem', '@hubot restaurants']);
            expect(this.room.messages[1][1]).to.match(/:fork_knife_plate: Restaurants:/);
            expect(this.room.messages[1][1]).to.include("asia-wok-man");
            expect(this.room.messages[1][1]).to.not.include("'"); // bug in RocketChat/Hubot, renders as entity &#39;
        });
    });

    context('user wants to see a list of restaurants but forgets the s', function() {
        beforeEach(function() {
            return co(function*() {
                yield this.room.user.say('lorem', '@hubot restaurant');
            }.bind(this));
        });

        it('should list restaurants', function() {
            expect(this.room.messages[0]).to.eql(['lorem', '@hubot restaurant']);
            expect(this.room.messages[1][1]).to.match(/:fork_knife_plate: Restaurants:/);
            expect(this.room.messages[1][1]).to.include("asia-wok-man");
            expect(this.room.messages[1][1]).to.not.include("'"); // bug in RocketChat/Hubot, renders as entity &#39;
        });
    });

    context('user wants to know who should pickup lunch, but nobody has ordered yet', function() {
        beforeEach(function() {
            return co(function*() {
                yield this.room.user.say('lorem', '@hubot who should order');
            }.bind(this));
        });

        it('should tell that nobody ordered any lunch yet', function() {
            expect(this.room.messages[0]).to.eql(['lorem', '@hubot who should order']);
            expect(this.room.messages[1][1]).to.eql('Hmm... Looks like no one has ordered any lunch yet today.');
        });
    });

    context('user wants to know who should pickup lunch', function() {
        beforeEach(function() {
            return co(function*() {
                yield this.room.user.say('lorem', '@hubot @ipsum wants Tofu Zitronengras');
                yield this.room.user.say('lorem', '@hubot who should order');
            }.bind(this));
        });

        it('should tell that @ipsum should pickup lunch', function() {
            expect(this.room.messages).to.eql([
                ['lorem', '@hubot @ipsum wants Tofu Zitronengras'],
                ['hubot', 'ok, added Tofu Zitronengras to @ipsum order.'],
                ['lorem', '@hubot who should order'],
                ['hubot', '@ipsum looks like you have to order lunch today!']
            ]);
        });
    });
});