import Vue from 'vue/dist/vue.esm'
import store from './store'
import axios from 'axios'

var token = document.getElementsByName('csrf-token')[0].getAttribute('content');
axios.defaults.headers.common['X-CSRF-Token'] = token;
axios.defaults.headers.common['Accept'] = 'application/json';

new Vue({
    el: '#step2-app',
    store,
    components: {
    }
});