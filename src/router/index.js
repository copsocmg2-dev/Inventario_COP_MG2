import { createRouter, createWebHistory } from 'vue-router'
import AdminDashboard from '../views/AdminDashboard.vue'
import LeaderMobile from '../views/LeaderMobile.vue'

const routes = [
    { path: '/', redirect: '/admin' },
    { path: '/admin', name: 'Admin', component: AdminDashboard },
    { path: '/lider', name: 'Lider', component: LeaderMobile }
]

const router = createRouter({
    history: createWebHistory(),
    routes
})

export default router
