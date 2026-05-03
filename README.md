{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {
    "id": "u98L9TgH0eMk"
   },
   "source": [
    "# Разработка A/B-тестирования и анализ результатов\n",
    "\n",
    "Вы работаете продуктовым аналитиком в компании, которая разрабатывает развлекательное приложение с функцией «бесконечной» ленты, как, например, в приложениях с короткими видео. В вашем приложении существует две модели монетизации: первая — ежемесячная платная подписка, которая позволяет пользователям смотреть ленту без рекламы, вторая — демонстрация рекламы для пользователей, которые ещё не оформили подписку.\n",
    "\n",
    "Команда разработчиков рекомендательных систем создала новый алгоритм рекомендаций, который, по их мнению, будет показывать более интересный контент для каждого пользователя. Вас, как аналитика, просят помочь рассчитать параметры A/B-теста, который позволит проверить эту гипотезу, и проанализировать его результаты."
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {
    "id": "LJBRALHs0eMf"
   },
   "source": [
    "## Описание данных\n",
    "\n",
    "Вы будете работать с тремя таблицами:\n",
    "\n",
    "- `sessions_project_history.csv` — таблица с историческими данными по сессиям пользователей на период с 2025-08-15 по 2025-09-23. Путь к файлу: `/datasets/sessions_project_history.csv`.\n",
    "\n",
    "- `sessions_project_test_part.csv` — таблица с данными за первый день проведения A/B-теста, то есть за 2025-10-14. Путь к файлу: `/datasets/sessions_project_test_part.csv`.\n",
    "\n",
    "- `sessions_project_test.csv` — таблица с данными за весь период проведения A/B-теста, то есть с 2025-10-14 по 2025-11-02. Путь к файлу: `/datasets/sessions_project_test.csv`.\n",
    "\n",
    "У этих таблиц почти совпадает структура и содержание колонок, различаются лишь периоды наблюдения.\n",
    "\n",
    "Поля таблиц `sessions_project_history.csv`, `sessions_project_test.csv`, `sessions_project_test_part.csv`:\n",
    "\n",
    "- `user_id` — идентификатор пользователя;\n",
    "\n",
    "- `session_id` — идентификатор сессии в приложении;\n",
    "\n",
    "- `session_date` — дата сессии;\n",
    "\n",
    "- `session_start_ts` — дата и время начала сессии;\n",
    "\n",
    "- `install_date` — дата установки приложения;\n",
    "\n",
    "- `session_number` — порядковый номер сессии для конкретного пользователя;\n",
    "\n",
    "- `registration_flag` — является ли пользователь зарегистрированным;\n",
    "\n",
    "- `page_counter` — количество просмотренных страниц во время сессии;\n",
    "\n",
    "- `region` — регион пользователя;\n",
    "\n",
    "- `device` — тип устройства пользователя;\n",
    "\n",
    "- `test_group` — тестовая группа (в таблице с историческими данными этого столбца нет).\n",
    "\n",
    "\n",
    "## Что нужно сделать\n",
    "Ваши задачи: рассчитать параметры теста, оценить корректность его проведения и проанализировать результаты эксперимента."
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {
    "id": "UpOucjID0eMl"
   },
   "source": [
    "### 1. Работа с историческими данными (EDA)"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {
    "id": "8iJMtL-30eMl"
   },
   "source": [
    "#### 1.1. Загрузка исторических данных\n",
    "На первом этапе поработайте с историческими данными приложения:\n",
    "\n",
    "- Импортируйте библиотеку pandas.\n",
    "\n",
    "- Считайте и сохраните в датафрейм `sessions_history` CSV-файл с историческими данными о сессиях пользователей `sessions_project_history.csv`.\n",
    "\n",
    "Выведите на экран первые пять строк полученного датафрейма."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 2,
   "metadata": {
    "id": "sg0CwxsaDEbo"
   },
   "outputs": [],
   "source": [
    "import pandas as pd\n",
    "import numpy as np\n",
    "import matplotlib.pyplot as plt\n",
    "from math import ceil\n",
    "from statsmodels.stats.proportion import proportions_ztest, proportion_confint, proportion_effectsize\n",
    "from statsmodels.stats.power import NormalIndPower"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 3,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Настройка отображения\n",
    "pd.set_option('display.max_columns', None)\n",
    "plt.style.use('ggplot')\n",
    "%matplotlib inline"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 4,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Загружаем исторические данные\n",
    "sessions_history = pd.read_csv('/datasets/sessions_project_history.csv')"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 5,
   "metadata": {},
   "outputs": [
    {
     "data": {
      "text/html": [
       "<div>\n",
       "<style scoped>\n",
       "    .dataframe tbody tr th:only-of-type {\n",
       "        vertical-align: middle;\n",
       "    }\n",
       "\n",
       "    .dataframe tbody tr th {\n",
       "        vertical-align: top;\n",
       "    }\n",
       "\n",
       "    .dataframe thead th {\n",
       "        text-align: right;\n",
       "    }\n",
       "</style>\n",
       "<table border=\"1\" class=\"dataframe\">\n",
       "  <thead>\n",
       "    <tr style=\"text-align: right;\">\n",
       "      <th></th>\n",
       "      <th>user_id</th>\n",
       "      <th>session_id</th>\n",
       "      <th>session_date</th>\n",
       "      <th>session_start_ts</th>\n",
       "      <th>install_date</th>\n",
       "      <th>session_number</th>\n",
       "      <th>registration_flag</th>\n",
       "      <th>page_counter</th>\n",
       "      <th>region</th>\n",
       "      <th>device</th>\n",
       "    </tr>\n",
       "  </thead>\n",
       "  <tbody>\n",
       "    <tr>\n",
       "      <th>0</th>\n",
       "      <td>E302123B7000BFE4</td>\n",
       "      <td>F9AF61A0C2023832</td>\n",
       "      <td>2025-08-15</td>\n",
       "      <td>2025-08-15 17:47:35</td>\n",
       "      <td>2025-08-15</td>\n",
       "      <td>1</td>\n",
       "      <td>0</td>\n",
       "      <td>3</td>\n",
       "      <td>CIS</td>\n",
       "      <td>iPhone</td>\n",
       "    </tr>\n",
       "    <tr>\n",
       "      <th>1</th>\n",
       "      <td>2530F72E221829FB</td>\n",
       "      <td>85003A206CBDAC6F</td>\n",
       "      <td>2025-08-15</td>\n",
       "      <td>2025-08-15 16:42:14</td>\n",
       "      <td>2025-08-15</td>\n",
       "      <td>1</td>\n",
       "      <td>0</td>\n",
       "      <td>4</td>\n",
       "      <td>MENA</td>\n",
       "      <td>Android</td>\n",
       "    </tr>\n",
       "    <tr>\n",
       "      <th>2</th>\n",
       "      <td>876E020A4FC512F5</td>\n",
       "      <td>3677423E49D72DEE</td>\n",
       "      <td>2025-08-15</td>\n",
       "      <td>2025-08-15 12:30:00</td>\n",
       "      <td>2025-08-15</td>\n",
       "      <td>1</td>\n",
       "      <td>0</td>\n",
       "      <td>4</td>\n",
       "      <td>EU</td>\n",
       "      <td>PC</td>\n",
       "    </tr>\n",
       "    <tr>\n",
       "      <th>3</th>\n",
       "      <td>2640B349E1D81584</td>\n",
       "      <td>956B45F5915CA225</td>\n",
       "      <td>2025-08-15</td>\n",
       "      <td>2025-08-15 15:31:31</td>\n",
       "      <td>2025-08-15</td>\n",
       "      <td>1</td>\n",
       "      <td>0</td>\n",
       "      <td>4</td>\n",
       "      <td>CIS</td>\n",
       "      <td>Android</td>\n",
       "    </tr>\n",
       "    <tr>\n",
       "      <th>4</th>\n",
       "      <td>94E1CBFAEF1F5EE9</td>\n",
       "      <td>83BF0DA35F9F1F40</td>\n",
       "      <td>2025-08-15</td>\n",
       "      <td>2025-08-15 21:33:53</td>\n",
       "      <td>2025-08-15</td>\n",
       "      <td>1</td>\n",
       "      <td>0</td>\n",
       "      <td>3</td>\n",
       "      <td>CIS</td>\n",
       "      <td>Android</td>\n",
       "    </tr>\n",
       "  </tbody>\n",
       "</table>\n",
       "</div>"
      ],
      "text/plain": [
       "            user_id        session_id session_date     session_start_ts  \\\n",
       "0  E302123B7000BFE4  F9AF61A0C2023832   2025-08-15  2025-08-15 17:47:35   \n",
       "1  2530F72E221829FB  85003A206CBDAC6F   2025-08-15  2025-08-15 16:42:14   \n",
       "2  876E020A4FC512F5  3677423E49D72DEE   2025-08-15  2025-08-15 12:30:00   \n",
       "3  2640B349E1D81584  956B45F5915CA225   2025-08-15  2025-08-15 15:31:31   \n",
       "4  94E1CBFAEF1F5EE9  83BF0DA35F9F1F40   2025-08-15  2025-08-15 21:33:53   \n",
       "\n",
       "  install_date  session_number  registration_flag  page_counter region  \\\n",
       "0   2025-08-15               1                  0             3    CIS   \n",
       "1   2025-08-15               1                  0             4   MENA   \n",
       "2   2025-08-15               1                  0             4     EU   \n",
       "3   2025-08-15               1                  0             4    CIS   \n",
       "4   2025-08-15               1                  0             3    CIS   \n",
       "\n",
       "    device  \n",
       "0   iPhone  \n",
       "1  Android  \n",
       "2       PC  \n",
       "3  Android  \n",
       "4  Android  "
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "display(sessions_history.head())"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {
    "id": "qTDoiODz0eMo"
   },
   "source": [
    "#### 1.2. Знакомство с данными\n",
    "- Для каждого уникального пользователя `user_id` рассчитайте количество уникальных сессий `session_id`.\n",
    "\n",
    "- Выведите на экран все данные из таблицы `sessions_history` для одного пользователя с наибольшим количеством сессий. Если таких пользователей несколько, выберите любого из них.\n",
    "\n",
    "- Изучите таблицу для одного пользователя, чтобы лучше понять логику формирования каждого столбца данных."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 6,
   "metadata": {
    "id": "LF9YRDgMDNta",
    "scrolled": true
   },
   "outputs": [
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "ТОП-5 ПОЛЬЗОВАТЕЛЕЙ ПО КОЛИЧЕСТВУ СЕССИЙ:\n"
     ]
    },
    {
     "data": {
      "text/html": [
       "<div>\n",
       "<style scoped>\n",
       "    .dataframe tbody tr th:only-of-type {\n",
       "        vertical-align: middle;\n",
       "    }\n",
       "\n",
       "    .dataframe tbody tr th {\n",
       "        vertical-align: top;\n",
       "    }\n",
       "\n",
       "    .dataframe thead th {\n",
       "        text-align: right;\n",
       "    }\n",
       "</style>\n",
       "<table border=\"1\" class=\"dataframe\">\n",
       "  <thead>\n",
       "    <tr style=\"text-align: right;\">\n",
       "      <th></th>\n",
       "      <th>user_id</th>\n",
       "      <th>session_count</th>\n",
       "    </tr>\n",
       "  </thead>\n",
       "  <tbody>\n",
       "    <tr>\n",
       "      <th>8948</th>\n",
       "      <td>10E0DEFC1ABDBBE0</td>\n",
       "      <td>10</td>\n",
       "    </tr>\n",
       "    <tr>\n",
       "      <th>55627</th>\n",
       "      <td>6A73CB5566BB494D</td>\n",
       "      <td>10</td>\n",
       "    </tr>\n",
       "    <tr>\n",
       "      <th>72346</th>\n",
       "      <td>8A60431A825D035B</td>\n",
       "      <td>9</td>\n",
       "    </tr>\n",
       "    <tr>\n",
       "      <th>109383</th>\n",
       "      <td>D11541BAC141FB94</td>\n",
       "      <td>9</td>\n",
       "    </tr>\n",
       "    <tr>\n",
       "      <th>47956</th>\n",
       "      <td>5BCFE7C4DCC148E9</td>\n",
       "      <td>9</td>\n",
       "    </tr>\n",
       "  </tbody>\n",
       "</table>\n",
       "</div>"
      ],
      "text/plain": [
       "                 user_id  session_count\n",
       "8948    10E0DEFC1ABDBBE0             10\n",
       "55627   6A73CB5566BB494D             10\n",
       "72346   8A60431A825D035B              9\n",
       "109383  D11541BAC141FB94              9\n",
       "47956   5BCFE7C4DCC148E9              9"
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\n",
      "ДАННЫЕ ПОЛЬЗОВАТЕЛЯ С МАКСИМАЛЬНОЙ АКТИВНОСТЬЮ (10 сессий):\n",
      "User ID: 10E0DEFC1ABDBBE0\n",
      "\n",
      "Все сессии пользователя:\n"
     ]
    },
    {
     "data": {
      "text/html": [
       "<div>\n",
       "<style scoped>\n",
       "    .dataframe tbody tr th:only-of-type {\n",
       "        vertical-align: middle;\n",
       "    }\n",
       "\n",
       "    .dataframe tbody tr th {\n",
       "        vertical-align: top;\n",
       "    }\n",
       "\n",
       "    .dataframe thead th {\n",
       "        text-align: right;\n",
       "    }\n",
       "</style>\n",
       "<table border=\"1\" class=\"dataframe\">\n",
       "  <thead>\n",
       "    <tr style=\"text-align: right;\">\n",
       "      <th></th>\n",
       "      <th>user_id</th>\n",
       "      <th>session_id</th>\n",
       "      <th>session_date</th>\n",
       "      <th>session_start_ts</th>\n",
       "      <th>install_date</th>\n",
       "      <th>session_number</th>\n",
       "      <th>registration_flag</th>\n",
       "      <th>page_counter</th>\n",
       "      <th>region</th>\n",
       "      <th>device</th>\n",
       "    </tr>\n",
       "  </thead>\n",
       "  <tbody>\n",
       "    <tr>\n",
       "      <th>115558</th>\n",
       "      <td>10E0DEFC1ABDBBE0</td>\n",
       "      <td>B8F0423BBFFCF5DC</td>\n",
       "      <td>2025-08-14</td>\n",
       "      <td>2025-08-14 13:57:39</td>\n",
       "      <td>2025-08-14</td>\n",
       "      <td>1</td>\n",
       "      <td>0</td>\n",
       "      <td>4</td>\n",
       "      <td>CIS</td>\n",
       "      <td>Android</td>\n",
       "    </tr>\n",
       "    <tr>\n",
       "      <th>191751</th>\n",
       "      <td>10E0DEFC1ABDBBE0</td>\n",
       "      <td>87CA2FA549473837</td>\n",
       "      <td>2025-08-15</td>\n",
       "      <td>2025-08-15 16:42:10</td>\n",
       "      <td>2025-08-14</td>\n",
       "      <td>2</td>\n",
       "      <td>0</td>\n",
       "      <td>3</td>\n",
       "      <td>CIS</td>\n",
       "      <td>Android</td>\n",
       "    </tr>\n",
       "    <tr>\n",
       "      <th>239370</th>\n",
       "      <td>10E0DEFC1ABDBBE0</td>\n",
       "      <td>4ADD8011DCDCE318</td>\n",
       "      <td>2025-08-16</td>\n",
       "      <td>2025-08-16 19:53:21</td>\n",
       "      <td>2025-08-14</td>\n",
       "      <td>3</td>\n",
       "      <td>0</td>\n",
       "      <td>3</td>\n",
       "      <td>CIS</td>\n",
       "      <td>Android</td>\n",
       "    </tr>\n",
       "    <tr>\n",
       "      <th>274629</th>\n",
       "      <td>10E0DEFC1ABDBBE0</td>\n",
       "      <td>DF0FD0E09BF1F3D7</td>\n",
       "      <td>2025-08-17</td>\n",
       "      <td>2025-08-17 15:03:43</td>\n",
       "      <td>2025-08-14</td>\n",
       "      <td>4</td>\n",
       "      <td>0</td>\n",
       "      <td>1</td>\n",
       "      <td>CIS</td>\n",
       "      <td>Android</td>\n",
       "    </tr>\n",
       "    <tr>\n",
       "      <th>302501</th>\n",
       "      <td>10E0DEFC1ABDBBE0</td>\n",
       "      <td>3C221774B4DE6885</td>\n",
       "      <td>2025-08-18</td>\n",
       "      <td>2025-08-18 17:29:14</td>\n",
       "      <td>2025-08-14</td>\n",
       "      <td>5</td>\n",
       "      <td>0</td>\n",
       "      <td>4</td>\n",
       "      <td>CIS</td>\n",
       "      <td>Android</td>\n",
       "    </tr>\n",
       "    <tr>\n",
       "      <th>325557</th>\n",
       "      <td>10E0DEFC1ABDBBE0</td>\n",
       "      <td>031BD7A67048105B</td>\n",
       "      <td>2025-08-19</td>\n",
       "      <td>2025-08-19 13:23:55</td>\n",
       "      <td>2025-08-14</td>\n",
       "      <td>6</td>\n",
       "      <td>0</td>\n",
       "      <td>2</td>\n",
       "      <td>CIS</td>\n",
       "      <td>Android</td>\n",
       "    </tr>\n",
       "    <tr>\n",
       "      <th>345336</th>\n",
       "      <td>10E0DEFC1ABDBBE0</td>\n",
       "      <td>FF4315CF4AD4B100</td>\n",
       "      <td>2025-08-20</td>\n",
       "      <td>2025-08-20 19:31:54</td>\n",
       "      <td>2025-08-14</td>\n",
       "      <td>7</td>\n",
       "      <td>0</td>\n",
       "      <td>2</td>\n",
       "      <td>CIS</td>\n",
       "      <td>Android</td>\n",
       "    </tr>\n",
       "    <tr>\n",
       "      <th>377532</th>\n",
       "      <td>10E0DEFC1ABDBBE0</td>\n",
       "      <td>4045FEA0747203B4</td>\n",
       "      <td>2025-08-22</td>\n",
       "      <td>2025-08-22 17:54:13</td>\n",
       "      <td>2025-08-14</td>\n",
       "      <td>8</td>\n",
       "      <td>0</td>\n",
       "      <td>2</td>\n",
       "      <td>CIS</td>\n",
       "      <td>Android</td>\n",
       "    </tr>\n",
       "    <tr>\n",
       "      <th>403538</th>\n",
       "      <td>10E0DEFC1ABDBBE0</td>\n",
       "      <td>344B086C421C7F37</td>\n",
       "      <td>2025-08-24</td>\n",
       "      <td>2025-08-24 14:46:13</td>\n",
       "      <td>2025-08-14</td>\n",
       "      <td>9</td>\n",
       "      <td>0</td>\n",
       "      <td>2</td>\n",
       "      <td>CIS</td>\n",
       "      <td>Android</td>\n",
       "    </tr>\n",
       "    <tr>\n",
       "      <th>414743</th>\n",
       "      <td>10E0DEFC1ABDBBE0</td>\n",
       "      <td>054F20BA371E4C9D</td>\n",
       "      <td>2025-08-25</td>\n",
       "      <td>2025-08-25 18:36:41</td>\n",
       "      <td>2025-08-14</td>\n",
       "      <td>10</td>\n",
       "      <td>0</td>\n",
       "      <td>3</td>\n",
       "      <td>CIS</td>\n",
       "      <td>Android</td>\n",
       "    </tr>\n",
       "  </tbody>\n",
       "</table>\n",
       "</div>"
      ],
      "text/plain": [
       "                 user_id        session_id session_date     session_start_ts  \\\n",
       "115558  10E0DEFC1ABDBBE0  B8F0423BBFFCF5DC   2025-08-14  2025-08-14 13:57:39   \n",
       "191751  10E0DEFC1ABDBBE0  87CA2FA549473837   2025-08-15  2025-08-15 16:42:10   \n",
       "239370  10E0DEFC1ABDBBE0  4ADD8011DCDCE318   2025-08-16  2025-08-16 19:53:21   \n",
       "274629  10E0DEFC1ABDBBE0  DF0FD0E09BF1F3D7   2025-08-17  2025-08-17 15:03:43   \n",
       "302501  10E0DEFC1ABDBBE0  3C221774B4DE6885   2025-08-18  2025-08-18 17:29:14   \n",
       "325557  10E0DEFC1ABDBBE0  031BD7A67048105B   2025-08-19  2025-08-19 13:23:55   \n",
       "345336  10E0DEFC1ABDBBE0  FF4315CF4AD4B100   2025-08-20  2025-08-20 19:31:54   \n",
       "377532  10E0DEFC1ABDBBE0  4045FEA0747203B4   2025-08-22  2025-08-22 17:54:13   \n",
       "403538  10E0DEFC1ABDBBE0  344B086C421C7F37   2025-08-24  2025-08-24 14:46:13   \n",
       "414743  10E0DEFC1ABDBBE0  054F20BA371E4C9D   2025-08-25  2025-08-25 18:36:41   \n",
       "\n",
       "       install_date  session_number  registration_flag  page_counter region  \\\n",
       "115558   2025-08-14               1                  0             4    CIS   \n",
       "191751   2025-08-14               2                  0             3    CIS   \n",
       "239370   2025-08-14               3                  0             3    CIS   \n",
       "274629   2025-08-14               4                  0             1    CIS   \n",
       "302501   2025-08-14               5                  0             4    CIS   \n",
       "325557   2025-08-14               6                  0             2    CIS   \n",
       "345336   2025-08-14               7                  0             2    CIS   \n",
       "377532   2025-08-14               8                  0             2    CIS   \n",
       "403538   2025-08-14               9                  0             2    CIS   \n",
       "414743   2025-08-14              10                  0             3    CIS   \n",
       "\n",
       "         device  \n",
       "115558  Android  \n",
       "191751  Android  \n",
       "239370  Android  \n",
       "274629  Android  \n",
       "302501  Android  \n",
       "325557  Android  \n",
       "345336  Android  \n",
       "377532  Android  \n",
       "403538  Android  \n",
       "414743  Android  "
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "# Рассчитываем количество уникальных сессий для каждого пользователя\n",
    "sessions_per_user = sessions_history.groupby('user_id')['session_id'].nunique().reset_index()\n",
    "sessions_per_user.columns = ['user_id', 'session_count']\n",
    "sessions_per_user = sessions_per_user.sort_values('session_count', ascending=False)\n",
    "\n",
    "print(\"ТОП-5 ПОЛЬЗОВАТЕЛЕЙ ПО КОЛИЧЕСТВУ СЕССИЙ:\")\n",
    "display(sessions_per_user.head())\n",
    "\n",
    "# Находим пользователя с наибольшим количеством сессий\n",
    "top_user = sessions_per_user.iloc[0]['user_id']\n",
    "top_user_sessions = sessions_per_user.iloc[0]['session_count']\n",
    "\n",
    "print(f\"\\nДАННЫЕ ПОЛЬЗОВАТЕЛЯ С МАКСИМАЛЬНОЙ АКТИВНОСТЬЮ ({top_user_sessions} сессий):\")\n",
    "print(f\"User ID: {top_user}\")\n",
    "print(\"\\nВсе сессии пользователя:\")\n",
    "\n",
    "# Выводим все данные для этого пользователя\n",
    "user_data = sessions_history[sessions_history['user_id'] == top_user]\n",
    "display(user_data)"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {
    "id": "CmcGpJTP0eMq"
   },
   "source": [
    "#### 1.3. Анализ числа регистраций\n",
    "Одна из важнейших метрик продукта — число зарегистрированных пользователей. Используя исторические данные, визуализируйте, как менялось число регистраций в приложении за время его существования. Пользователь считается зарегистрированным только в день совершения регистрации. Таким образом, вам необходимо проанализировать количество зарегистрированных активных пользователей за каждый день без накопления (аналог DAU, но для регистраций пользователей).\n",
    "\n",
    "- Агрегируйте исторические данные и рассчитайте число уникальных пользователей и число зарегистрированных пользователей для каждого дня наблюдения. Для простоты считайте, что у пользователя в течение дня бывает одна сессия максимум и статус регистрации в течение одного дня не может измениться.\n",
    "\n",
    "- Постройте линейные графики общего числа пользователей и общего числа зарегистрированных пользователей по дням. Отобразите их на одном графике.\n",
    "\n",
    "- Постройте отдельный линейный график доли зарегистрированных пользователей от всех пользователей по дням.\n",
    "\n",
    "- На обоих графиках должны быть заголовок, подписанные оси X и Y, сетка и легенда."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 7,
   "metadata": {
    "id": "lTprzQbFDbFr"
   },
   "outputs": [
    {
     "data": {
      "image/png": "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AaXKLQUihBAJYcyUP9m0o6jc9hYNAkw4oWuNztmmTRtefvnlkkVwb775Zp599lkuu+yyWsUq4p8MERRC1Jj96lNYvRznuNNQTu3fTpRSqNP/Cd0OwL74JPaXbyMQpaguu3UL7qO3gFI4l9+EatKswv1U2/aoEafBd1/Bgi/qOEohhIicipKryraHo1mzZiXJleu65OXl0axZM1566SWGDx/OkCFDGDt2LLm5uQBcccUVXHvttRx11FEcdthhzJo1C4CioiJuu+22kmMmTfKWx5gzZw577703WVlZZGVlceeddwLQtevOhHDUqFGceeaZAGzfvp0rr7ySwYMHM2TIEN555x3GjRtHVlYWBx98MPvuuy9ZWVlcc801LFu2jP79+3PJJZcwYMCAUnEecsghZGdnA3DppZcyaNAgACZPnszZZ5/NiSeeSL9+/XjwwQdL4njmmWfo378/gwYN4tlnnwVg2bJldOnShaysLPr27cutt95aEqfWmiOPPJLBgwczc+bMkv2Lnwvg7bff5oorrij53b399tsljw0aNIhly5aVO6ZY8O/oqaeeKvnd3n///eE2b6WkB0sIUSO2sBD71ivQsTMcELmFglVKCs6F1+Lecy3uY7d7c302b/LW1xo1Wha1jTJbkI/7xO2QvR7nmjtQbdpXur8aMgL79ee4Lz+Ds/d+IZMxIYSIpefmr2Hxxh01OvY/s/6ucHvnlg0476C2lR6bm5vLcccdx8qVK+nSpQu33XYbW7du5fTTTwfgnnvu4ZVXXuGcc84BYPny5bzzzjssWbKEk046icMPP5zXX3+dpk2bMmPGDPLy8hg5ciQDBgwAoHfv3kycOLHC5/7ggw/YunUrTZs2BeDhhx+madOmfPjhhwBs2rSJFi1acP755zN58mR++OEH7rjjDsBLZhYtWsQDDzzAwQcfzFVXXcWECRO48MILS87/66+/8ttvv5V6zu+++44PP/yQhg0bcvTRRzN48GCUUhhjePfddyksLOSYY46hb9++NG/enE6dOjFr1izWrVvHEUccwU033UR6ejrPP/88TZs2JTs7m2OPPZahQ4dW+nuuqU8++YTFixfzzjvvYK3lrLPOYu7cufTpU7vPNdKDJYSoEfvlR7BuNc6I0yPSexVMNWwEh2VBYQFs3ghYyF6HnfQE7tzZEX0usZN1XW/O1aLfcM67CtVl7yqPUYEAzlmXQs42rHk++kEKIUQCadiwIbNmzeL777+nW7duPProo/z++++MGjWKwYMHM3XqVH7//feS/Y899lgcx2GPPfagU6dOLFy4kE8++YTXX3+drKwsjjnmGDZu3MjixYsrfV5rLY8++iiXXnppybbPPvuMs846q+R+ixYtKj1H+/btOfjggwE4/vjjmTdvXqnH7733Xq655ppS2w4//HAyMjJo2LAhRx11FPPmzWPevHkMGzaMxo0b07hxY4466ii++uorAP7++2+ysrI4/PDDOffcc0tiv/vuuxkyZAgnn3wyq1evZt26daX2z8rK4vbbby/13LfffnvJY3//vTMpDj7mkUceKXXMJ598wieffMLQoUM58sgjWbRoUZW/23BID5YQotpsYQH2HQOd94L9Do7Ok8x6s/y2/Dzs1EkgvVhRYadOws7/HHXi2ahe/cI+TnXojDrqROzbk7EH90ft2yuKUQohRPVV1dM04qXfQj52R1anWj9/SkoKI0aM4Mknn+S1117j+eefp3v37kyePJkvv/yyZL+yc1mL799+++0MHDiw1GNz5swJ+XzTpk2jb9++tG7dusYxh4oFYP78+TRu3Jhu3bqFfUxFinuwcnNzOeqoo9Ba8/nnn7NhwwbeffddUlNTOeSQQ8jLyyu1P3hDBD/44IOSc914440cc8wxAKWGBQY/R1ZWFkcffXTJY9ZaLrnkEkaPjuySI9KDJYSoNvv5LNiw1pt7Fa3CBtnrq7dd1Ir76XvY96agBgxDDR1Z7ePVcA3tOuK++AR2R07kAxRCiATz119/sWLFCsD7IP/+++9zwAEHsG3bNtq2bUtBQQFTp04tdczbb7+N67osWbKEv//+my5dujBgwAAmTpxIgb9O5KJFi8jJCf0+67ouzz33HBdddFGp7f379+eFF14oub9p06ZK41+xYgXz588HvIStuDcL4IEHHijXewVeL9nGjRvJzc1l5syZHHzwwRxyyCHMnDmTnJwccnJyeO+99zjkkENKHZeWlkYgEGDz5s1s3bqVzMxMUlNT+eKLL1i+fHmlcYarQYMGNGzYkMLCwpJtAwcOZPLkyWzfvh2AVatWsX597T9nSA+WEKJabH6e13u15z7Q/YDoPVFGJmSvq3i7iCj70wLsS09Dj16oUy+oUdKsUlNxxlyKe8+12Dcmok67sOqDhBAi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\n",
      "text/plain": [
       "<Figure size 864x360 with 1 Axes>"
      ]
     },
     "metadata": {
      "needs_background": "light"
     },
     "output_type": "display_data"
    },
    {
     "data": {
      "image/png": "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Mjkf6JlzfJhP9gcW2ee4yFdGluM4l+PlbAmwHu96eIIicF33UcdxNuLN0vc0XgXtd7wPXMD7YKKRL7a1+RbiXznZ/Ln+i8Pf90ROU/FaucBb9Di35/FzVk3Hm4wlEbjXdd3cY8HyFYBWeREpIsd1tRyCSHnjeOulfOW6boEfZzq+9Wtc1x1cKkEFke+5NHJd95xQx1JSjreWzxuu6/6vhOWMJ0JeE5GyzPHW+Xsox4dCOfedgzcpzOBSDktEgkgtWCLlUzreejhH4neXFRERKdB2vL+5+TmA/taKRBxVsETKId/6KfULOeaOUgpHRCRiua7b9wj7vqPgCSpEJEypi6CIiIiIiEiAaKFhERERERGRAAnHLoJqchMRERERkbIgz4Rh4VjBIiUlJdQhyBHEx8ezdWvuGYAlEii3Eg50nUYu5TayKb+RK1Jzm5CQkO92dREUEREREREJEFWwREREREREAkQVLBERERERkQBRBUtERERERCRAVMESEREREREJEFWwREREREREAkQVLBERERERkQBRBUtERERERAIuMSmRzlM6U/nxynSe0pnEpMRQh1QqwnKhYRERERERKbsSkxIZ/t1w0jLSAEhOTWb4d8MB6NuibyhDCzq1YImIiIiISECNWjDqUOUqW1pGGqMWjApRRKVHFSwREREREQmolNSUIm2PJKpgiYiIiIhIQCXEJRRpeyRRBUtERERERAIqv3FWsdGxjOg0IgTRlC5VsEREREREJKAWblpI9YrVSajqtVhVrlCZ0d1HR/wEF6AKloiIiIiIBNCPG3/kh40/cFfHu1gwcAHXtb+OilEVuaj5RaEOrVSogiUiIiIiIgHz3K/PUTe2LlcedyUAZzU5iz0H97Bk65IQR1Y6VMESEREREZGAWLBpAd8lf8eNJ95IbHQsAGc0OQOAuclzQxlaqVEFS0REREREAuL5X56nduXaXN366kPb6lapS+varZmXMi+EkZUeVbBERERERKTEft38K19t+IobT7iRKhWrHLava0JXFm5ayP6M/SGKrvREl8ZJjDFvAX2Azdbatr5tTwIXAunAGmCItXZnacQjIiIiIiKB9dyvz1EzpibXtLkmz76uCV15Y9kb/Lz5Z7omdA1BdKWntFqwxgPn59r2GdDWWnsi8DtwTynFIiIiIiIiAbR061I+//Nzhp4wlLhKcXn2n9rg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\n",
      "text/plain": [
       "<Figure size 864x360 with 1 Axes>"
      ]
     },
     "metadata": {
      "needs_background": "light"
     },
     "output_type": "display_data"
    }
   ],
   "source": [
    "# Преобразуем даты\n",
    "sessions_history['session_date'] = pd.to_datetime(sessions_history['session_date'])\n",
    "\n",
    "# Агрегируем данные по дням\n",
    "daily_stats = sessions_history.groupby('session_date').agg(\n",
    "    total_users=('user_id', 'nunique'),\n",
    "    registered_users=('user_id', lambda x: sessions_history.loc[x.index, 'registration_flag'].sum())\n",
    ").reset_index()\n",
    "\n",
    "# График общего числа пользователей и зарегистрированных пользователей\n",
    "plt.figure(figsize=(12, 5))\n",
    "plt.plot(daily_stats['session_date'], daily_stats['total_users'], label='Все пользователи', marker='o')\n",
    "plt.plot(daily_stats['session_date'], daily_stats['registered_users'], label='Зарегистрированные', marker='s')\n",
    "plt.title('Динамика числа пользователей по дням')\n",
    "plt.xlabel('Дата')\n",
    "plt.ylabel('Количество пользователей')\n",
    "plt.grid(True)\n",
    "plt.legend()\n",
    "plt.xticks(rotation=45)\n",
    "plt.tight_layout()\n",
    "plt.show()\n",
    "\n",
    "# График доли зарегистрированных пользователей\n",
    "daily_stats['registered_share'] = daily_stats['registered_users'] / daily_stats['total_users'] * 100\n",
    "\n",
    "plt.figure(figsize=(12, 5))\n",
    "plt.plot(daily_stats['session_date'], daily_stats['registered_share'], marker='o', color='green')\n",
    "plt.title('Доля зарегистрированных пользователей по дням')\n",
    "plt.xlabel('Дата')\n",
    "plt.ylabel('Доля зарегистрированных (%)')\n",
    "plt.grid(True)\n",
    "plt.xticks(rotation=45)\n",
    "plt.tight_layout()\n",
    "plt.show()"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {
    "id": "UR7D7RhF0eMr"
   },
   "source": [
    "#### 1.4. Анализ числа просмотренных страниц\n",
    "Другая важная метрика продукта — число просмотренных страниц в приложении. Чем больше страниц просмотрено, тем сильнее пользователь увлечён контентом, а значит, выше шансы, что он зарегистрируется и оплатит подписку.\n",
    "\n",
    "В рамках задания проанализируйте число просмотренных страниц во время первых сессий пользователей. Найдите количество первых сессий для каждого значения количества просмотренных страниц. Например: одну страницу просмотрели в 29 160 сессиях, две страницы — в 105 536 сессиях и так далее.\n",
    "\n",
    "- Постройте столбчатую диаграмму, где по оси X будет число просмотренных страниц, по оси Y — количество сессий.\n",
    "\n",
    "- На диаграмме должны быть заголовок, подписанные оси X и Y."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 8,
   "metadata": {
    "id": "GB0bcnnzDwjn",
    "scrolled": true
   },
   "outputs": [
    {
     "data": {
      "image/png": "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\n",
      "text/plain": [
       "<Figure size 1008x432 with 1 Axes>"
      ]
     },
     "metadata": {
      "needs_background": "light"
     },
     "output_type": "display_data"
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "1     8978\n",
      "2    32494\n",
      "3    50939\n",
      "4    32739\n",
      "5     8075\n",
      "6      777\n",
      "7       37\n",
      "Name: page_counter, dtype: int64\n"
     ]
    }
   ],
   "source": [
    "# Находим первые сессии пользователей\n",
    "first_sessions = sessions_history.sort_values('session_start_ts').groupby('user_id').first().reset_index()\n",
    "\n",
    "# Подсчитываем количество сессий для каждого значения просмотренных страниц\n",
    "pages_distribution = first_sessions['page_counter'].value_counts().sort_index()\n",
    "\n",
    "# Строим столбчатую диаграмму\n",
    "plt.figure(figsize=(14, 6))\n",
    "plt.bar(pages_distribution.index, pages_distribution.values, width=0.8)\n",
    "plt.title('Распределение первых сессий по количеству просмотренных страниц')\n",
    "plt.xlabel('Количество просмотренных страниц')\n",
    "plt.ylabel('Количество сессий')\n",
    "plt.grid(True, axis='y')\n",
    "plt.tight_layout()\n",
    "plt.show()\n",
    "\n",
    "print(pages_distribution.head(10))"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {
    "id": "xDltSpVP0eMr"
   },
   "source": [
    "#### 1.5. Доля пользователей, просмотревших более четырёх страниц\n",
    "Продуктовая команда продукта считает, что сессии, в рамках которых пользователь просмотрел 4 и более страниц, говорят об удовлетворённости контентом и алгоритмами рекомендаций. Этот показатель является важной прокси-метрикой для продукта.\n",
    "\n",
    "- В датафрейме `sessions_history` создайте дополнительный столбец `good_session`. В него войдёт значение `1`, если за одну сессию было просмотрено 4 и более страниц, и значение `0`, если было просмотрено меньше.\n",
    "\n",
    "- Постройте график со средним значением доли успешных сессий от всех первых сессий пользователей. Данные нужно визуализировать по дням за весь период наблюдения."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 9,
   "metadata": {
    "id": "DivNKaY6D77Y"
   },
   "outputs": [
    {
     "data": {
      "image/png": "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\n",
      "text/plain": [
       "<Figure size 864x360 with 1 Axes>"
      ]
     },
     "metadata": {
      "needs_background": "light"
     },
     "output_type": "display_data"
    }
   ],
   "source": [
    "# Создаем столбец good_session\n",
    "sessions_history['good_session'] = (sessions_history['page_counter'] >= 4).astype(int)\n",
    "\n",
    "# Находим первые сессии\n",
    "first_sessions = sessions_history.sort_values('session_start_ts').groupby('user_id').first().reset_index()\n",
    "\n",
    "# Рассчитываем долю успешных сессий по дням\n",
    "daily_good_sessions = first_sessions.groupby('session_date')['good_session'].mean().reset_index()\n",
    "\n",
    "# Строим график\n",
    "plt.figure(figsize=(12, 5))\n",
    "plt.plot(daily_good_sessions['session_date'], daily_good_sessions['good_session'], marker='o', color='purple')\n",
    "plt.title('Доля успешных первых сессий по дням')\n",
    "plt.xlabel('Дата')\n",
    "plt.ylabel('Доля успешных сессий')\n",
    "plt.grid(True)\n",
    "plt.xticks(rotation=45)\n",
    "plt.tight_layout()\n",
    "plt.show()"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {
    "id": "21JcG77Y0eMt"
   },
   "source": [
    "### 2. Подготовка к тесту\n",
    "При планировании теста необходимо проделать несколько важных шагов:\n",
    "\n",
    "- Определиться с целевой метрикой.\n",
    "\n",
    "- Рассчитать необходимый размер выборки.\n",
    "\n",
    "- Исходя из текущих значений трафика рассчитать необходимую длительность проведения теста."
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {
    "id": "uzaeln270eMt"
   },
   "source": [
    "#### 2.1. Расчёт размера выборки\n",
    "В рамках курса вы уже рассчитывали размеры выборки и  использовали для этого онлайн-калькулятор. В этом задании предлагаем воспользоваться готовым кодом и рассчитать необходимое для вашего эксперимента количество пользователей.\n",
    "\n",
    "Для этого установите в коде ниже следующие параметры:\n",
    "\n",
    "- Уровень значимости — 0.05.\n",
    "\n",
    "- Вероятность ошибки второго рода — 0.2.\n",
    "\n",
    "- Мощность теста.\n",
    "\n",
    "- Минимальный детектируемый эффект, или MDE, — 3%. Обратите внимание, что здесь нужно указать десятичную дробь, а не процент.\n",
    "\n",
    "При расчёте размера выборки используйте метод `solve_power()` из класса `power.NormalIndPower` модуля `statsmodels.stats`.\n",
    "\n",
    "Запустите ячейку и изучите полученное значение."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 10,
   "metadata": {
    "id": "AkaSX45aEu12"
   },
   "outputs": [
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "РАСЧЕТ РАЗМЕРА ВЫБОРКИ ДЛЯ A/B-ТЕСТА\n",
      "============================================================\n",
      "Базовый уровень метрики (p): 0.3106 (31.06%)\n",
      "Относительный MDE: 3.0%\n",
      "Абсолютный MDE: 0.0093 (0.93%)\n",
      "Целевое значение после улучшения: 0.3199 (31.99%)\n",
      "Размер эффекта (Cohen's h): -0.0201\n",
      "\n",
      "============================================================\n",
      "РЕЗУЛЬТАТЫ РАСЧЕТА:\n",
      "Необходимый размер выборки для КАЖДОЙ группы: 39034 пользователей\n",
      "Общий размер выборки (обе группы): 78068 пользователей\n"
     ]
    }
   ],
   "source": [
    "print(\"РАСЧЕТ РАЗМЕРА ВЫБОРКИ ДЛЯ A/B-ТЕСТА\")\n",
    "print(\"=\"*60)\n",
    "\n",
    "# Задаем параметры\n",
    "alpha = 0.05      # Уровень значимости (5%)\n",
    "beta = 0.2        # Ошибка второго рода (20%)\n",
    "power = 1 - beta  # Мощность теста (80%)\n",
    "\n",
    "# Базовый уровень из исторических данных (доля успешных первых сессий)\n",
    "# Рассчитываем точно из наших данных\n",
    "first_sessions = sessions_history[sessions_history['session_number'] == 1].drop_duplicates('user_id')\n",
    "p = first_sessions['good_session'].mean()\n",
    "print(f\"Базовый уровень метрики (p): {p:.4f} ({p*100:.2f}%)\")\n",
    "\n",
    "# Минимальный детектируемый эффект - 3% ОТНОСИТЕЛЬНЫХ от базового значения\n",
    "relative_mde = 0.03  # 3% относительных\n",
    "absolute_mde = p * relative_mde  # Преобразуем в абсолютное изменение\n",
    "\n",
    "print(f\"Относительный MDE: {relative_mde*100}%\")\n",
    "print(f\"Абсолютный MDE: {absolute_mde:.4f} ({absolute_mde*100:.2f}%)\")\n",
    "print(f\"Целевое значение после улучшения: {p + absolute_mde:.4f} ({(p + absolute_mde)*100:.2f}%)\")\n",
    "\n",
    "# Рассчитываем размер эффекта (effect size)\n",
    "# Это мера различия между пропорциями в терминах стандартного отклонения\n",
    "effect_size = proportion_effectsize(p, p + absolute_mde)\n",
    "print(f\"Размер эффекта (Cohen's h): {effect_size:.4f}\")\n",
    "\n",
    "# Инициализируем класс для анализа мощности\n",
    "power_analysis = NormalIndPower()\n",
    "\n",
    "# Расчёт размера выборки для ОДНОЙ группы\n",
    "sample_size_per_group = power_analysis.solve_power(\n",
    "    effect_size=effect_size,\n",
    "    power=power,\n",
    "    alpha=alpha,\n",
    "    ratio=1  # Равное соотношение групп\n",
    ")\n",
    "\n",
    "# Округляем вверх до целого числа\n",
    "sample_size_per_group = ceil(sample_size_per_group)\n",
    "\n",
    "print(\"\\n\" + \"=\"*60)\n",
    "print(\"РЕЗУЛЬТАТЫ РАСЧЕТА:\")\n",
    "print(f\"Необходимый размер выборки для КАЖДОЙ группы: {sample_size_per_group} пользователей\")\n",
    "print(f\"Общий размер выборки (обе группы): {sample_size_per_group * 2} пользователей\")"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {
    "id": "qLEv4RoV0eMu"
   },
   "source": [
    "#### 2.2. Расчёт длительности A/B-теста\n",
    "\n",
    "Используйте данные о количестве пользователей в каждой выборке и среднем количестве пользователей приложения. Рассчитайте длительность теста, разделив одно на другое.\n",
    "\n",
    "- Рассчитайте среднее количество уникальных пользователей приложения в день.\n",
    "\n",
    "- Определите длительность теста исходя из рассчитанного значения размера выборок и среднего дневного трафика приложения. Количество дней округлите в большую сторону."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 11,
   "metadata": {
    "id": "Jl2Zy3SfE6dl"
   },
   "outputs": [
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "Средний дневной трафик (DAU): 9907 пользователей\n",
      "\n",
      "РЕЗУЛЬТАТЫ РАСЧЕТА:\n"
     ]
    },
    {
     "data": {
      "text/html": [
       "<div>\n",
       "<style scoped>\n",
       "    .dataframe tbody tr th:only-of-type {\n",
       "        vertical-align: middle;\n",
       "    }\n",
       "\n",
       "    .dataframe tbody tr th {\n",
       "        vertical-align: top;\n",
       "    }\n",
       "\n",
       "    .dataframe thead th {\n",
       "        text-align: right;\n",
       "    }\n",
       "</style>\n",
       "<table border=\"1\" class=\"dataframe\">\n",
       "  <thead>\n",
       "    <tr style=\"text-align: right;\">\n",
       "      <th></th>\n",
       "      <th>Параметр</th>\n",
       "      <th>Значение</th>\n",
       "    </tr>\n",
       "  </thead>\n",
       "  <tbody>\n",
       "    <tr>\n",
       "      <th>0</th>\n",
       "      <td>Средний дневной трафик (DAU)</td>\n",
       "      <td>9907 пользователей</td>\n",
       "    </tr>\n",
       "    <tr>\n",
       "      <th>1</th>\n",
       "      <td>Размер выборки на одну группу</td>\n",
       "      <td>39034 пользователей</td>\n",
       "    </tr>\n",
       "    <tr>\n",
       "      <th>2</th>\n",
       "      <td>Всего пользователей (две группы)</td>\n",
       "      <td>78068 пользователей</td>\n",
       "    </tr>\n",
       "    <tr>\n",
       "      <th>3</th>\n",
       "      <td>Расчетная длительность (дней)</td>\n",
       "      <td>7.9 дней</td>\n",
       "    </tr>\n",
       "    <tr>\n",
       "      <th>4</th>\n",
       "      <td>Длительность с округлением</td>\n",
       "      <td>8 дней</td>\n",
       "    </tr>\n",
       "  </tbody>\n",
       "</table>\n",
       "</div>"
      ],
      "text/plain": [
       "                           Параметр             Значение\n",
       "0      Средний дневной трафик (DAU)   9907 пользователей\n",
       "1     Размер выборки на одну группу  39034 пользователей\n",
       "2  Всего пользователей (две группы)  78068 пользователей\n",
       "3     Расчетная длительность (дней)             7.9 дней\n",
       "4        Длительность с округлением               8 дней"
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "# Среднее количество уникальных пользователей в день по историческим данным\n",
    "avg_daily_users = sessions_history.groupby('session_date')['user_id'].nunique().mean()\n",
    "print(f\"Средний дневной трафик (DAU): {avg_daily_users:.0f} пользователей\")\n",
    "\n",
    "# Используем sample_size_per_group из предыдущего расчета (с правильным MDE)\n",
    "# Если переменная не определена, рассчитаем заново\n",
    "try:\n",
    "    sample_size_per_group\n",
    "except NameError:\n",
    "    # Повторный расчет с правильным MDE\n",
    "    from statsmodels.stats.proportion import proportion_effectsize\n",
    "    from statsmodels.stats.power import NormalIndPower\n",
    "    \n",
    "    first_sessions = sessions_history[sessions_history['session_number'] == 1].drop_duplicates('user_id')\n",
    "    p = first_sessions['good_session'].mean()\n",
    "    \n",
    "    alpha = 0.05\n",
    "    beta = 0.2\n",
    "    power = 1 - beta\n",
    "    relative_mde = 0.03\n",
    "    absolute_mde = p * relative_mde\n",
    "    \n",
    "    effect_size = proportion_effectsize(p, p + absolute_mde)\n",
    "    power_analysis = NormalIndPower()\n",
    "    sample_size_per_group = power_analysis.solve_power(\n",
    "        effect_size=effect_size,\n",
    "        power=power,\n",
    "        alpha=alpha,\n",
    "        ratio=1\n",
    "    )\n",
    "    sample_size_per_group = ceil(sample_size_per_group)\n",
    "\n",
    "# ВАЖНО: Умножаем на 2, так как у нас две группы (A и B)\n",
    "total_users_needed = sample_size_per_group * 2\n",
    "\n",
    "# Рассчитываем длительность теста в днях\n",
    "test_duration = ceil(total_users_needed / avg_daily_users)\n",
    "\n",
    "# Создаем DataFrame для красивого отображения результатов\n",
    "results_df = pd.DataFrame({\n",
    "    'Параметр': [\n",
    "        'Средний дневной трафик (DAU)',\n",
    "        'Размер выборки на одну группу',\n",
    "        'Всего пользователей (две группы)',\n",
    "        'Расчетная длительность (дней)',\n",
    "        'Длительность с округлением'\n",
    "    ],\n",
    "    'Значение': [\n",
    "        f'{avg_daily_users:.0f} пользователей',\n",
    "        f'{sample_size_per_group} пользователей',\n",
    "        f'{total_users_needed} пользователей',\n",
    "        f'{total_users_needed/avg_daily_users:.1f} дней',\n",
    "        f'{test_duration} дней'\n",
    "    ]\n",
    "})\n",
    "\n",
    "print(\"\\nРЕЗУЛЬТАТЫ РАСЧЕТА:\")\n",
    "display(results_df)"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {
    "id": "ZuvtAdha0eMv"
   },
   "source": [
    "### 3. Мониторинг А/В-теста"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {
    "id": "jq5sE3Ya0eMv"
   },
   "source": [
    "#### 3.1. Проверка распределения пользователей\n",
    "\n",
    "A/B-тест успешно запущен, и уже доступны данные за первые три дня. На этом этапе нужно убедиться, что всё идёт хорошо: пользователи разделены правильным образом, а интересующие вас метрики корректно считаются.\n",
    "\n",
    "- Считайте и сохраните в датафрейм `sessions_test_part` CSV-файл с историческими данными о сессиях пользователей `sessions_project_test_part.csv`.\n",
    "\n",
    "- Рассчитайте количество уникальных пользователей в каждой из экспериментальных групп для одного дня наблюдения.\n",
    "\n",
    "- Рассчитайте и выведите на экран процентную разницу в количестве пользователей в группах A и B. Постройте любую удобную визуализацию, на которой будет видно возможное различие двух групп.\n",
    "\n",
    "Для расчёта процентной разницы воспользуйтесь формулой:\n",
    "$$P = 100 \\cdot  \\frac{|A − B|}{A}$$"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 12,
   "metadata": {
    "id": "Qm6RP2K0FJAE"
   },
   "outputs": [
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "Количество пользователей в группах:\n",
      "test_group\n",
      "A    1477\n",
      "B    1466\n",
      "Name: user_id, dtype: int64\n",
      "\n",
      "Процентная разница между группами: 0.74%\n"
     ]
    },
    {
     "data": {
      "image/png": "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\n",
      "text/plain": [
       "<Figure size 576x360 with 1 Axes>"
      ]
     },
     "metadata": {
      "needs_background": "light"
     },
     "output_type": "display_data"
    }
   ],
   "source": [
    "# Считываем данные за первый день теста\n",
    "sessions_test_part = pd.read_csv('/datasets/sessions_project_test_part.csv')\n",
    "\n",
    "# Рассчитываем количество уникальных пользователей в каждой группе\n",
    "users_per_group = sessions_test_part.groupby('test_group')['user_id'].nunique()\n",
    "print(\"Количество пользователей в группах:\")\n",
    "print(users_per_group)\n",
    "\n",
    "# Рассчитываем процентную разницу\n",
    "group_a = users_per_group.get('A', 0)\n",
    "group_b = users_per_group.get('B', 0)\n",
    "percent_diff = 100 * abs(group_a - group_b) / group_a if group_a > 0 else 0\n",
    "print(f\"\\nПроцентная разница между группами: {percent_diff:.2f}%\")\n",
    "\n",
    "# Визуализация\n",
    "plt.figure(figsize=(8, 5))\n",
    "plt.bar(users_per_group.index, users_per_group.values, color=['blue', 'orange'])\n",
    "plt.title('Распределение пользователей по группам (первый день теста)')\n",
    "plt.xlabel('Тестовая группа')\n",
    "plt.ylabel('Количество пользователей')\n",
    "plt.grid(True, axis='y')\n",
    "plt.show()"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {
    "id": "sgpNY5bv0eM0"
   },
   "source": [
    "#### 3.2. Проверка пересечений пользователей\n",
    "Помимо проверки равенства количества пользователей в группах, полезно убедиться в том, что группы независимы. Для этого нужно убедиться, что никто из пользователей случайно не попал в обе группы одновременно.\n",
    "\n",
    "- Рассчитайте количество пользователей, которые встречаются одновременно в группах A и B, или убедитесь, что таких нет."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 13,
   "metadata": {
    "id": "0Wmt_1J2FNEd"
   },
   "outputs": [
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "Количество пользователей, попавших в обе группы: 0\n",
      "Пересечений нет - группы независимы\n"
     ]
    }
   ],
   "source": [
    "# Находим пользователей в каждой группе\n",
    "users_a = set(sessions_test_part[sessions_test_part['test_group'] == 'A']['user_id'].unique())\n",
    "users_b = set(sessions_test_part[sessions_test_part['test_group'] == 'B']['user_id'].unique())\n",
    "\n",
    "# Проверяем пересечение\n",
    "intersection = users_a.intersection(users_b)\n",
    "print(f\"Количество пользователей, попавших в обе группы: {len(intersection)}\")\n",
    "\n",
    "if len(intersection) == 0:\n",
    "    print(\"Пересечений нет - группы независимы\")\n",
    "else:\n",
    "    print(f\"Обнаружены пересечения: {intersection}\")"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {
    "id": "6RvkNLrg0eM1"
   },
   "source": [
    "#### 3.3. Равномерность разделения пользователей по устройствам\n",
    "Полезно также убедиться в том, что пользователи равномерно распределены по всем доступным категориальным переменным — типам устройств и регионам.\n",
    "\n",
    "Постройте две диаграммы:\n",
    "\n",
    "- доля каждого типа устройства для пользователей из группы A,\n",
    "\n",
    "- доля каждого типа устройства для пользователей из группы B.\n",
    "\n",
    "Постарайтесь добавить на диаграммы все необходимые подписи, пояснения и заголовки, которые позволят сделать вывод о том, совпадает ли распределение устройств в группах A и B.\n"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 14,
   "metadata": {
    "id": "GzNmwC2mFX2G",
    "scrolled": true
   },
   "outputs": [
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\n",
      "РАСПРЕДЕЛЕНИЕ ПО УСТРОЙСТВАМ (%):\n"
     ]
    },
    {
     "data": {
      "text/html": [
       "<div>\n",
       "<style scoped>\n",
       "    .dataframe tbody tr th:only-of-type {\n",
       "        vertical-align: middle;\n",
       "    }\n",
       "\n",
       "    .dataframe tbody tr th {\n",
       "        vertical-align: top;\n",
       "    }\n",
       "\n",
       "    .dataframe thead th {\n",
       "        text-align: right;\n",
       "    }\n",
       "</style>\n",
       "<table border=\"1\" class=\"dataframe\">\n",
       "  <thead>\n",
       "    <tr style=\"text-align: right;\">\n",
       "      <th></th>\n",
       "      <th>Группа A</th>\n",
       "      <th>Группа B</th>\n",
       "    </tr>\n",
       "    <tr>\n",
       "      <th>device</th>\n",
       "      <th></th>\n",
       "      <th></th>\n",
       "    </tr>\n",
       "  </thead>\n",
       "  <tbody>\n",
       "    <tr>\n",
       "      <th>Android</th>\n",
       "      <td>44.41</td>\n",
       "      <td>45.57</td>\n",
       "    </tr>\n",
       "    <tr>\n",
       "      <th>Mac</th>\n",
       "      <td>10.56</td>\n",
       "      <td>10.10</td>\n",
       "    </tr>\n",
       "    <tr>\n",
       "      <th>PC</th>\n",
       "      <td>24.98</td>\n",
       "      <td>25.99</td>\n",
       "    </tr>\n",
       "    <tr>\n",
       "      <th>iPhone</th>\n",
       "      <td>20.04</td>\n",
       "      <td>18.35</td>\n",
       "    </tr>\n",
       "  </tbody>\n",
       "</table>\n",
       "</div>"
      ],
      "text/plain": [
       "         Группа A  Группа B\n",
       "device                     \n",
       "Android     44.41     45.57\n",
       "Mac         10.56     10.10\n",
       "PC          24.98     25.99\n",
       "iPhone      20.04     18.35"
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\n",
      "РАЗНИЦА МЕЖДУ ГРУППАМИ:\n"
     ]
    },
    {
     "data": {
      "text/html": [
       "<div>\n",
       "<style scoped>\n",
       "    .dataframe tbody tr th:only-of-type {\n",
       "        vertical-align: middle;\n",
       "    }\n",
       "\n",
       "    .dataframe tbody tr th {\n",
       "        vertical-align: top;\n",
       "    }\n",
       "\n",
       "    .dataframe thead th {\n",
       "        text-align: right;\n",
       "    }\n",
       "</style>\n",
       "<table border=\"1\" class=\"dataframe\">\n",
       "  <thead>\n",
       "    <tr style=\"text-align: right;\">\n",
       "      <th></th>\n",
       "      <th>Группа A</th>\n",
       "      <th>Группа B</th>\n",
       "      <th>Разница (п.п.)</th>\n",
       "    </tr>\n",
       "    <tr>\n",
       "      <th>device</th>\n",
       "      <th></th>\n",
       "      <th></th>\n",
       "      <th></th>\n",
       "    </tr>\n",
       "  </thead>\n",
       "  <tbody>\n",
       "    <tr>\n",
       "      <th>Android</th>\n",
       "      <td>44.41</td>\n",
       "      <td>45.57</td>\n",
       "      <td>1.15</td>\n",
       "    </tr>\n",
       "    <tr>\n",
       "      <th>Mac</th>\n",
       "      <td>10.56</td>\n",
       "      <td>10.10</td>\n",
       "      <td>-0.47</td>\n",
       "    </tr>\n",
       "    <tr>\n",
       "      <th>PC</th>\n",
       "      <td>24.98</td>\n",
       "      <td>25.99</td>\n",
       "      <td>1.01</td>\n",
       "    </tr>\n",
       "    <tr>\n",
       "      <th>iPhone</th>\n",
       "      <td>20.04</td>\n",
       "      <td>18.35</td>\n",
       "      <td>-1.69</td>\n",
       "    </tr>\n",
       "  </tbody>\n",
       "</table>\n",
       "</div>"
      ],
      "text/plain": [
       "         Группа A  Группа B  Разница (п.п.)\n",
       "device                                     \n",
       "Android     44.41     45.57            1.15\n",
       "Mac         10.56     10.10           -0.47\n",
       "PC          24.98     25.99            1.01\n",
       "iPhone      20.04     18.35           -1.69"
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\n",
      "Максимальная разница: 1.69 п.п.\n",
      "Средняя разница: 1.08 п.п.\n"
     ]
    },
    {
     "data": {
      "image/png": "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7W9ceumlDS5n8uTJfPTRRwwZMqTBOuPHj6dfv37ssssurbuSUoklNY2nMpJ65/QlvMN45+W277zc9u3DvHnz6NatG127Fu9cSdeuXVm0aFHRltcepGlam9Tq3r37UuPyJ0gUJ7tWerZ/muBvY+fi9u5c3N6di9u7aQ21gYpyk2VJkjqaxYsXFzW501klSUL37t2prq4udSiSJEntmgkeSZJWQLEuy1LGz1uSJKlxnnqUJKkVnH/x5Xzw0dxWn+/aq6/KT88+o8l6AwYMYKWVVmKllVaqLZswYcJSj5xtjz755BO+9rWvccQRRzB69OhShyNJklS2TPBIktQKPvhoLos2P7D15/vKfc2uO27cODbbbLNWj6Et3XvvvWy//fbce++9jBw5ksrKylKHJEmSVJa8REuSpA7s6aefZo899uC0005j1113Zb/99uP1118H4Mgjj2TSpEm1dR988EEOO+wwAIYMGcLAgQPZc8892XPPPdlmm224/PLLAbj88svZZpttascNHDiw9mklM2fOZMiQIQwePJhdd92Viy66qNH47rzzTk4//XQ233xzHnroobb4CCRJkjoFEzySJHVwr7zyCocddhiTJ0/m6KOP5vTTTwfg2GOP5ZZbbqmtd/PNNzNs2LDa4dGjR/Pwww/z8MMPL/O42SFDhtSOK7y0qlevXtxyyy388Y9/5E9/+hP/+te/mDx5cr1xvfzyy8yePZudd96ZoUOHMn78+FZca0mSpM7FBI8kSR1c//79GThwIJAlZl599VXmzp3LoEGDmDlzJm+88QZvvPEG06ZNY4899mjRshYvXsyFF17IHnvswT777MNrr73GSy+9VG/dO++8kyFDhpAkCfvssw///Oc/mTFjRouWL0mS1Fl5Dx5JkjqpJEk45phjanvxfO9736OioqJF87zhhhv49NNP+f3vf0/37t0566yzqKqqWqbeggULmDhxIpWVlUyYMAGAhQsXEmOs7WEkSZKk5jPB00m89dZb7Lbbbtx111288847XHnllay77roAXHPNNfTr12+p+h9//DHnnHMOH330EV27duWOO+5gxowZnHjiiQBcf/319OvXj0ceeYQZM2Zw5JFHFn2dJEnNM23aNJ555hkGDBjAxIkT2WyzzVh11VUBOOSQQxg0aBALFixo8FKq5TFnzhz69u1L9+7dmTFjBg899BBHHXXUMvUeeughNtpoI+69997asmeffZbTTz/dBE8J3HDnDUybPa3UYbRIjx49mDdvXqnDaLH1v7Q+Jxx6QqnDkCSVIRM8ncTYsWPZYYcdaocPPfRQRowY0WD9888/nx/+8IdsuummtWWTJk1i+PDhVFVVMWnSJIYNG8bEiRO55ppr2jJ0SVILbbbZZvzud7/j7LPPpkePHlx11VW141ZZZRV23XVX5s+fz+qrr97iZR133HGccMIJ7LbbbvTr14+dd9653nrjx4/noIMOWqrs61//Omma8te//rX2kjIVx7TZ05i+4fRSh9EilZWVLFiwoNRhtNzbpQ5AklSuTPB0Av/4xz/o27fvUt3uJ0yYwOOPP86OO+7ImWeeSZcuS27HVF1dzauvvsoNN9zAtGnTOOCAAxg2bBg9e/Zk7ty5VFdXs/LKK3PjjTdy/PHHLzWtJHVWa6++6nI90nx55tsczzzzTIPjunXrtlRSp9CiRYuYOnUqY8eOXaq85rKpGqNGjap9f8YZZyw1ruZpWgDrrrsuDzzwQJPx3nbbbfWWP/30001OK0mSpGWZ4OkErr76aq644orap5zsvffetU9D+eEPf8g999yz1NNRZs2axauvvsrYsWPZZJNNCCGw0047cfDBBzN69GjSNOX73/8+t956Kx9//DHnn38+W221FYccckhJ1k+S2oOfnn1G05XamT/96U+MHDmSwYMHs91225U6HEmSJLWACZ4O7pFHHmHbbbdltdVWqy3r06dP7fsDDzyQJ554YqkET+/evVlzzTXZcsstARg4cCCvvPIKm2yyCZdccgkA55xzDmeeeSYnnXQS48eP55hjjmH//fenR48exVkxSVKz7LjjjvzhD3+od9xee+3FXnvtVeSIJEmS1Ba8tqaDe+mll3j66ac54ogjePLJJxk9ejTvv/9+7finnnqKDTfccKlpunfvzvrrr8/06dm1+C+88AIbbLBB7fgpU6aw2WabsdpqqzF79mwAPvvss3qfkiJJkiRJktqePXg6uMKnkYwYMYLDDz+c2267jb/85S9UVFSw0UYbcfbZZwNw7bXXsvvuu7P55pvz05/+lNNOO42FCxey0047sfXWWwPZ/XnGjx/P5ZdfDsD+++/P/vvvz9Zbb71UzyBJkiRJklQ8SZqmpY5heaUffPBBqWNoN9ZYYw1mzZpV6jBUAm77zstt3z588cUX9OzZs6jL7Nq1K4sWLSrqMtuL+j7vtddeGyApSUDF16btn3OuO8enaLUT67y9Dj8/6eelDqPd81jYubi9Oxe3d9MaagN5idYKeuutt1h//fX529/+Vls2ZswYdtpppwanmT17NltuuSV33303AE888QT77rsvxx13HIsXLwbg4osv5rXXXmvb4CVJkiRJUodigmcFjR07lh122KF2+P/+7/94++23G53m2muv5Wtf+1rt8M0338xtt93Gaqutxssvv8ybb74JwKabbto2QUuSJEmSpA7Je/CsgH/84x/07duXioqK2rKxY8dy6qmn8v3vf7/eaaZPn87MmTPZdttta8t69uzJ3LlzmT9/Pj169OCaa67hoosuavP4JUmt77qfX8Cij2a0+ny7rt6Pk865oMl6AwYMYKWVVmKllVaqLZswYQK9e/du9ZhaS2HMVVVVDBgwgJ///Od069at1KFJkiSVHRM8K+Dqq6/miiuuYPTo0QC8/fbbfP7552yxxRYNTnPFFVdw2mmncf/999eW/fCHP+QXv/gFX/3qV3njjTfYZZdd+N3vfsf777/PwQcfzHbbbdfWqyJJaiWLPprBxZu2/mH17NeanzQaN24cm222WavH0JZqYq6uruaggw7iwQcf5MADDyx1WJIkSWXHS7SW0yOPPMK2227LaqutVlt2xRVXMGLEiAaneeWVV0iShE022WSp8o033phrr72W4cOH88c//pFtt92Wt99+m5EjR9Y+pUqSpJZ4+umn2WOPPTjttNPYdddd2W+//Xj99dcBOPLII5k0aVJt3QcffJDDDjsMgCFDhjBw4ED23HNP9txzT7bZZpvaY9Pll1/ONttsUztu4MCBDBkyBICZM2cyZMgQBg8ezK677trsnqlVVVVUVVX5REZJkqQVZA+e5fTSSy/x9NNP8+yzz/Lqq6/y5ptvMmvWLM4991wAPvzwQ8477zwuvPDC2mmef/553nrrLY444gjeffddevTowYYbbsj2228PZGcvTzjhBObNm8eCBQtI05TZs2eXZP0kSR3PK6+8woUXXsjVV19NjJHTTz+dP/zhDxx77LH88pe/5IADDgCye8Mdd9xxtdONHj2aPffcs/Z9oSFDhjBq1CgAHn74YW644QYAevXqxS233MLKK6/MwoULOfzww5k8eTK77rprvbENHz6c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wFr1jDo3xnhfKy9rODAcIMZIZWVla86+w0mSxM+oHbvpppuYNGkSG2ywAXPmzKndVp9//jlrrLHGUtvu1ltvJYTAKqusUrtda8ZXV1fz8MMPc/HFF5Omae00NeMrKiro2rVrvftCTVmXLl3o1q2b+0sZ8fvdPF0qKujSpWNcpFPu69GloqIk+6wJHkmSpGaKMe7RwllMB9YrGF43L6tvWeOAcflgumDBghYuumNL0xQ/o/brqKOO4qijjgLgwAMP5J133qFv375MmTKF008/falt99JLLzFt2jQmTJjAyy+/zIknnshtt91G9+7deeKJJ9h6661ZddVVmTVrVu00NdNXV1ezaNGieveFmrLFixezcOFC95cy4ve7eRZXV7N48eJSh9Eqyn09FldXl2SfLe+0mCRJUnmZCmwSQtgghFAJHArcX+KYpKIaPXo0J598Mt/97nc5+uija2+wfOqppwJwySWXcMcdd3D77bez+eabc/XVV9O9e3cguzzr4IMPbtZyRo0axUcffdRonZplSlJHYA8eqZkOP/xwXnjhBY477jhGjBhBmqacd955vPTSS6y66qpcddVVfOlLX1pqmnnz5nHeeefx3nvvsXjxYm666SYqKysZNmwYn3/+OZdddhlbbrklL7/8Mr///e8566yzSrR2kqSWCiEcBFwDfBl4IITwXIxx7xDC2mSPQ983xrgohHAq8BDZY9J/E2N8qYRhS0W37bbbct99y17ReO211y5TVnPfnBpXX331MnWeeuqp2vcjRoyofT969Oh664wZM6bRZUpSuTLBIzXTmDFjePLJJ5kxYwYAjz/+OPPmzWPixIncddddXHfddZxzzjlLTXPFFVdwwAEH8O1vf7u27A9/+AO77bYbX/va1xg/fjyjR4/muuuu49JLLy3q+kiSWleMcSIwsZ7yD4B9C4YfBB4sYmiSJKkT8BItqZnWXnvtpYanTJnCHntkt2LYc889+etf/7rMNE8++SSTJ09myJAhtWeLevbsydy5c5k3bx49e/bk3nvvZe+99673MaCSJEmSJDWHCR5pBRU+5rN37958+umny9R57bXX2Gmnnbjrrrt4/fXXmTx5Mt/61reYN28e99xzD0OHDuWJJ55g3XXXZdSoUYwbN26ZebTE4YcfztZbb137yNA0TRk5ciQHHXQQRx11FLNnz15mmptvvpmd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\n",
      "text/plain": [
       "<Figure size 1152x432 with 2 Axes>"
      ]
     },
     "metadata": {
      "needs_background": "light"
     },
     "output_type": "display_data"
    }
   ],
   "source": [
    "# Рассчитываем распределение по устройствам для группы A\n",
    "device_a = sessions_test_part[sessions_test_part['test_group'] == 'A'].groupby('device')['user_id'].nunique()\n",
    "device_a_pct = device_a / device_a.sum() * 100\n",
    "\n",
    "# Рассчитываем распределение по устройствам для группы B\n",
    "device_b = sessions_test_part[sessions_test_part['test_group'] == 'B'].groupby('device')['user_id'].nunique()\n",
    "device_b_pct = device_b / device_b.sum() * 100\n",
    "\n",
    "# Создаем DataFrame для сравнения\n",
    "device_comparison = pd.DataFrame({\n",
    "    'Группа A': device_a_pct,\n",
    "    'Группа B': device_b_pct\n",
    "}).fillna(0)  # заполняем NaN нулями, если какое-то устройство отсутствует в одной из групп\n",
    "\n",
    "print(\"\\nРАСПРЕДЕЛЕНИЕ ПО УСТРОЙСТВАМ (%):\")\n",
    "display(device_comparison.round(2))\n",
    "\n",
    "# Рассчитываем разницу между группами\n",
    "device_comparison['Разница (п.п.)'] = (device_comparison['Группа B'] - device_comparison['Группа A']).round(2)\n",
    "device_comparison['|Разница|'] = device_comparison['Разница (п.п.)'].abs()\n",
    "\n",
    "print(\"\\nРАЗНИЦА МЕЖДУ ГРУППАМИ:\")\n",
    "display(device_comparison[['Группа A', 'Группа B', 'Разница (п.п.)']].round(2))\n",
    "\n",
    "print(f\"\\nМаксимальная разница: {device_comparison['|Разница|'].max():.2f} п.п.\")\n",
    "print(f\"Средняя разница: {device_comparison['|Разница|'].mean():.2f} п.п.\")\n",
    "\n",
    "# Визуализация 1: Группированная столбчатая диаграмма (рекомендованный способ)\n",
    "fig, axes = plt.subplots(1, 2, figsize=(16, 6))\n",
    "\n",
    "# График 1: Группированные столбцы\n",
    "x = np.arange(len(device_comparison.index))\n",
    "width = 0.35\n",
    "\n",
    "ax1 = axes[0]\n",
    "bars1 = ax1.bar(x - width/2, device_comparison['Группа A'], width, label='Группа A', color='steelblue', edgecolor='black')\n",
    "bars2 = ax1.bar(x + width/2, device_comparison['Группа B'], width, label='Группа B', color='coral', edgecolor='black')\n",
    "\n",
    "ax1.set_xlabel('Тип устройства', fontsize=12)\n",
    "ax1.set_ylabel('Доля (%)', fontsize=12)\n",
    "ax1.set_title('Сравнение распределения устройств по группам', fontsize=14, fontweight='bold')\n",
    "ax1.set_xticks(x)\n",
    "ax1.set_xticklabels(device_comparison.index)\n",
    "ax1.legend(fontsize=11)\n",
    "ax1.grid(True, axis='y', alpha=0.3)\n",
    "ax1.set_ylim(0, max(device_comparison.max()) * 1.1)\n",
    "\n",
    "# Добавляем значения над столбцами\n",
    "for bars in [bars1, bars2]:\n",
    "    for bar in bars:\n",
    "        height = bar.get_height()\n",
    "        ax1.text(bar.get_x() + bar.get_width()/2., height + 1,\n",
    "                f'{height:.1f}%', ha='center', va='bottom', fontsize=9)\n",
    "\n",
    "# График 2: Разница между группами\n",
    "ax2 = axes[1]\n",
    "colors = ['green' if x > 0 else 'red' if x < 0 else 'gray' for x in device_comparison['Разница (п.п.)']]\n",
    "bars = ax2.bar(device_comparison.index, device_comparison['Разница (п.п.)'], \n",
    "               color=colors, edgecolor='black', alpha=0.7)\n",
    "ax2.set_xlabel('Тип устройства', fontsize=12)\n",
    "ax2.set_ylabel('Разница (п.п.)', fontsize=12)\n",
    "ax2.set_title('Разница в долях (Группа B - Группа A)', fontsize=14, fontweight='bold')\n",
    "ax2.grid(True, axis='y', alpha=0.3)\n",
    "ax2.axhline(y=0, color='black', linestyle='-', linewidth=0.5)\n",
    "\n",
    "# Добавляем значения над столбцами\n",
    "for bar in bars:\n",
    "    height = bar.get_height()\n",
    "    if height >= 0:\n",
    "        ax2.text(bar.get_x() + bar.get_width()/2., height + 0.2,\n",
    "                f'{height:+.2f}п.п.', ha='center', va='bottom', fontsize=9)\n",
    "    else:\n",
    "        ax2.text(bar.get_x() + bar.get_width()/2., height - 0.5,\n",
    "                f'{height:+.2f}п.п.', ha='center', va='top', fontsize=9)\n",
    "\n",
    "plt.tight_layout()\n",
    "plt.show()\n"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {
    "id": "gAgmP6vo0eM1"
   },
   "source": [
    "#### 3.4. Равномерность распределения пользователей по регионам\n",
    "Теперь убедитесь, что пользователи равномерно распределены по регионам.\n",
    "\n",
    "Постройте две диаграммы:\n",
    "\n",
    "- доля каждого региона для пользователей из группы A,\n",
    "\n",
    "- доля каждого региона для пользователей из группы B.\n",
    "\n",
    "Постарайтесь добавить на диаграммы все необходимые подписи, пояснения и заголовки, которые позволят сделать вывод о том, совпадает ли распределение регионов в группах A и B. Постарайтесь использовать другой тип диаграммы, не тот, что в прошлом задании."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 15,
   "metadata": {
    "id": "LEMMLuH4FcZv"
   },
   "outputs": [
    {
     "data": {
      "image/png": "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\n",
      "text/plain": [
       "<Figure size 1008x360 with 2 Axes>"
      ]
     },
     "metadata": {
      "needs_background": "light"
     },
     "output_type": "display_data"
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "Группа A:\n",
      "region\n",
      "CIS     43.60\n",
      "EU      15.17\n",
      "MENA    41.23\n",
      "Name: user_id, dtype: float64\n",
      "\n",
      "Группа B:\n",
      "region\n",
      "CIS     44.0\n",
      "EU      14.8\n",
      "MENA    41.2\n",
      "Name: user_id, dtype: float64\n"
     ]
    }
   ],
   "source": [
    "# Рассчитываем распределение по регионам для группы A\n",
    "region_a = sessions_test_part[sessions_test_part['test_group'] == 'A'].groupby('region')['user_id'].nunique()\n",
    "region_a_pct = region_a / region_a.sum() * 100\n",
    "\n",
    "# Рассчитываем распределение по регионам для группы B\n",
    "region_b = sessions_test_part[sessions_test_part['test_group'] == 'B'].groupby('region')['user_id'].nunique()\n",
    "region_b_pct = region_b / region_b.sum() * 100\n",
    "\n",
    "# Строим столбчатые диаграммы\n",
    "fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 5))\n",
    "\n",
    "ax1.bar(region_a_pct.index, region_a_pct.values, color='blue', alpha=0.7)\n",
    "ax1.set_title('Распределение регионов в группе A')\n",
    "ax1.set_xlabel('Регион')\n",
    "ax1.set_ylabel('Доля (%)')\n",
    "ax1.tick_params(axis='x', rotation=45)\n",
    "\n",
    "ax2.bar(region_b_pct.index, region_b_pct.values, color='orange', alpha=0.7)\n",
    "ax2.set_title('Распределение регионов в группе B')\n",
    "ax2.set_xlabel('Регион')\n",
    "ax2.set_ylabel('Доля (%)')\n",
    "ax2.tick_params(axis='x', rotation=45)\n",
    "\n",
    "plt.tight_layout()\n",
    "plt.show()\n",
    "\n",
    "print(\"Группа A:\")\n",
    "print(region_a_pct.round(2))\n",
    "print(\"\\nГруппа B:\")\n",
    "print(region_b_pct.round(2))"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {
    "id": "X2WSZ-sDrSUi"
   },
   "source": [
    "#### 3.5. Вывод после проверки A/B-теста\n",
    "\n",
    "На основе проведённого анализа A/B-теста сформулируйте и запишите свои выводы. В выводе обязательно укажите:\n",
    "\n",
    "- Было ли обнаружено различие в количестве пользователей в двух группах.\n",
    "\n",
    "- Являются ли выборки независимыми. Было ли обнаружено пересечение пользователей из тестовой и контрольной групп.\n",
    "\n",
    "- Сохраняется ли равномерное распределение пользователей тестовой и контрольной групп по категориальным переменным: устройствам и регионам.\n",
    "\n",
    "Сделайте заключение: корректно ли проходит A/B-тест, или наблюдаются какие-либо нарушения."
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {
    "id": "9b-mK4fIFlpq"
   },
   "source": []
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "## 2.3.5. Вывод после проверки A/B-теста\n",
    "\n",
    "**1. Различие в количестве пользователей в группах:**\n",
    "- Группа A: 1477 пользователей\n",
    "- Группа B: 1466 пользователей\n",
    "- Процентная разница: 0.74%\n",
    "- **Вывод:** Различие незначительное (менее 1%), что говорит о корректном распределении пользователей по группам.\n",
    "\n",
    "**2. Независимость выборок:**\n",
    "- Пересечений пользователей между группами A и B не обнаружено (0 пользователей)\n",
    "- **Вывод:** Выборки являются независимыми, что соответствует требованиям A/B-тестирования.\n",
    "\n",
    "**3. Равномерность распределения по категориальным переменным:**\n",
    "\n",
    "*По типам устройств:*\n",
    "- Группа A: Android (44.4%), iPhone (20.0%), PC (25.0%), Mac (10.6%)\n",
    "- Группа B: Android (45.6%), iPhone (18.4%), PC (26.0%), Mac (10.1%)\n",
    "- Различия в долях не превышают 2%\n",
    "- **Вывод:** Распределение по устройствам равномерное\n",
    "\n",
    "*По регионам:*\n",
    "- Группа A: CIS (43.6%), MENA (41.2%), EU (15.2%)\n",
    "- Группа B: CIS (44.0%), MENA (41.2%), EU (14.8%)\n",
    "- Различия в долях не превышают 0.5%\n",
    "- **Вывод:** Распределение по регионам равномерное\n",
    "\n",
    "**ЗАКЛЮЧЕНИЕ:**\n",
    "A/B-тест проходит корректно. Нарушений не обнаружено:\n",
    "- Пользователи распределены равномерно между группами\n",
    "- Группы независимы (нет пересечений)\n",
    "- Сохраняется равномерное распределение по устройствам и регионам\n",
    "\n",
    "Можно продолжать эксперимент и анализировать результаты."
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {
    "id": "nudRr_BQ0eM2"
   },
   "source": [
    "### 4. Проверка результатов A/B-теста\n",
    "\n",
    "A/B-тест завершён, и у вас есть результаты за все дни проведения эксперимента. Необходимо убедиться в корректности теста и верно интерпретировать результаты."
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {
    "id": "JVve-YBB0eM2"
   },
   "source": [
    "#### 4.1. Получение результатов теста и подсчёт основной метрики\n",
    "\n",
    "- Считайте и сохраните в датафрейм `sessions_test` CSV-файл с историческими данными о сессиях пользователей `sessions_project_test.csv`.\n",
    "\n",
    "- В датафрейме `sessions_test` создайте дополнительный столбец `good_session`. В него войдёт значение `1`, если за одну сессию было просмотрено 4 и более страниц, и значение `0`, если просмотрено меньше."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 16,
   "metadata": {
    "id": "JQhvlmwtGawa"
   },
   "outputs": [
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "Размер данных теста: (100005, 12)\n",
      "Период теста: с 2025-10-14 по 2025-11-02\n",
      "Уникальных пользователей: 30579\n"
     ]
    }
   ],
   "source": [
    "# Считываем данные за весь период теста\n",
    "sessions_test = pd.read_csv('/datasets/sessions_project_test.csv')\n",
    "\n",
    "# Создаем столбец good_session\n",
    "sessions_test['good_session'] = (sessions_test['page_counter'] >= 4).astype(int)\n",
    "\n",
    "print(f\"Размер данных теста: {sessions_test.shape}\")\n",
    "print(f\"Период теста: с {sessions_test['session_date'].min()} по {sessions_test['session_date'].max()}\")\n",
    "print(f\"Уникальных пользователей: {sessions_test['user_id'].nunique()}\")"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {
    "id": "KJ70tHxFvD32"
   },
   "source": [
    "#### 4.2 Формулировка нулевой и альтернативной гипотез. Определение целевой, прокси- и барьерных метрик\n",
    "\n",
    "\n",
    "Перед тем как проводить А/B-тест, необходимо сформулировать нулевую и альтернативную гипотезы. Напомним изначальное условие: команда разработчиков рекомендательных систем создала новый алгоритм, который, по их мнению, будет показывать более интересный контент для каждого пользователя.\n",
    "\n",
    "Подумайте, о какой метрике идёт речь и как она будет учтена в формулировке гипотез. Сформулируйте нулевую и альтернативную гипотезы.\n",
    "\n",
    "Не забывайте, что до проведения эксперимента важно выделять и отслеживать изменение прокси- и барьерных метрик. В имеющихся у вас данных о проведении эксперимента этих метрик нет. Подумайте, какие показатели вы бы выбрали в качестве прокси- и барьерных метрик, если бы проводили этот эксперимент самостоятельно."
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {
    "id": "W-T5sRHwGn4A"
   },
   "source": [
    "## 4.2 Формулировка нулевой и альтернативной гипотез. Определение целевой, прокси- и барьерных метрик\n",
    "\n",
    "### Целевая метрика\n",
    "Основная метрика, отражающая \"интересность контента\" — **доля успешных первых сессий** (просмотр 4 и более страниц). Именно эта метрика была выбрана продуктовой командой как прокси удовлетворённости контентом и алгоритмами рекомендаций.\n",
    "\n",
    "### Формулировка гипотез\n",
    "\n",
    "**Нулевая гипотеза (H₀):**\n",
    "Доля успешных первых сессий (с просмотром 4+ страниц) в группе с новым алгоритмом рекомендаций (B) не отличается от доли успешных первых сессий в контрольной группе (A) со старым алгоритмом.\n",
    "\n",
    "**Альтернативная гипотеза (H₁):**\n",
    "Доля успешных первых сессий (с просмотром 4+ страниц) в группе с новым алгоритмом рекомендаций (B) выше, чем в контрольной группе (A) со старым алгоритмом.\n",
    "\n",
    "### Прокси-метрики (дополнительные показатели вовлечённости)\n",
    "\n",
    "Прокси-метрики помогают быстрее оценить эффект и подтвердить результаты основной метрики:\n",
    "\n",
    "1. **Среднее количество просмотренных страниц за сессию** — показывает глубину вовлечённости\n",
    "2. **Среднее количество сессий на пользователя за период теста** — отражает возвращаемость пользователей\n",
    "3. **Среднее время, проведённое в приложении за сессию** — метрика вовлечённости (если бы были данные)\n",
    "4. **Доля пользователей, совершивших повторные сессии** — удержание пользователей\n",
    "\n",
    "### Барьерные метрики (метрики, которые не должны ухудшиться)\n",
    "\n",
    "Барьерные метрики отслеживают возможные негативные последствия изменений:\n",
    "\n",
    "1. **Отток пользователей (churn rate)** — процент пользователей, переставших использовать приложение\n",
    "2. **Доля пользователей, просмотревших менее 2 страниц за сессию** — индикатор разочарования контентом\n",
    "3. **Количество жалоб/обращений в поддержку** — показатель проблем с качеством контента\n",
    "4. **Частота ошибок и сбоев в приложении** — техническая стабильность\n",
    "5. **Конверсия в подписку** — ключевая бизнес-метрика, которая не должна снижаться\n",
    "\n",
    "### Обоснование выбора метрик\n",
    "\n",
    "Выбор **доли успешных первых сессий** в качестве целевой метрики обусловлен тем, что:\n",
    "- Первая сессия критически важна для формирования первого впечатления о приложении\n",
    "- Просмотр 4+ страниц показывает, что пользователь заинтересовался контентом и продолжил взаимодействие\n",
    "- Эта метрика чувствительна к изменениям в алгоритме рекомендаций\n",
    "- Данная метрика коррелирует с более высокими бизнес-показателями (регистрация, подписка)\n",
    "\n",
    "Барьерные метрики необходимы, чтобы убедиться, что новый алгоритм, повышая вовлечённость одной группы пользователей, не ухудшает опыт других и не создаёт технических проблем."
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {
    "id": "7kwRxzg70eM3"
   },
   "source": [
    "#### 4.3. Сравнение доли успешных сессий\n",
    "\n",
    "Перейдем к анализу ключевой метрики — доле успешных первых сессий.\n",
    "\n",
    "Используйте созданный на первом шаге задания столбец `good_session` и рассчитайте долю успешных первых сессий для выборок A и B, а также разницу в этом показателе. Полученный вывод отобразите на экране."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 17,
   "metadata": {
    "id": "WxcD67LOG2C-"
   },
   "outputs": [
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\n",
      "ИНФОРМАЦИЯ О ПЕРВЫХ СЕССИЯХ:\n"
     ]
    },
    {
     "data": {
      "text/html": [
       "<div>\n",
       "<style scoped>\n",
       "    .dataframe tbody tr th:only-of-type {\n",
       "        vertical-align: middle;\n",
       "    }\n",
       "\n",
       "    .dataframe tbody tr th {\n",
       "        vertical-align: top;\n",
       "    }\n",
       "\n",
       "    .dataframe thead th {\n",
       "        text-align: right;\n",
       "    }\n",
       "</style>\n",
       "<table border=\"1\" class=\"dataframe\">\n",
       "  <thead>\n",
       "    <tr style=\"text-align: right;\">\n",
       "      <th></th>\n",
       "      <th>Показатель</th>\n",
       "      <th>Значение</th>\n",
       "    </tr>\n",
       "  </thead>\n",
       "  <tbody>\n",
       "    <tr>\n",
       "      <th>0</th>\n",
       "      <td>Всего первых сессий</td>\n",
       "      <td>30,578</td>\n",
       "    </tr>\n",
       "    <tr>\n",
       "      <th>1</th>\n",
       "      <td>Уникальных пользователей</td>\n",
       "      <td>30,578</td>\n",
       "    </tr>\n",
       "  </tbody>\n",
       "</table>\n",
       "</div>"
      ],
      "text/plain": [
       "                 Показатель Значение\n",
       "0       Всего первых сессий   30,578\n",
       "1  Уникальных пользователей   30,578"
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\n",
      "РЕЗУЛЬТАТЫ ПО ГРУППАМ:\n"
     ]
    },
    {
     "data": {
      "text/html": [
       "<div>\n",
       "<style scoped>\n",
       "    .dataframe tbody tr th:only-of-type {\n",
       "        vertical-align: middle;\n",
       "    }\n",
       "\n",
       "    .dataframe tbody tr th {\n",
       "        vertical-align: top;\n",
       "    }\n",
       "\n",
       "    .dataframe thead th {\n",
       "        text-align: right;\n",
       "    }\n",
       "</style>\n",
       "<table border=\"1\" class=\"dataframe\">\n",
       "  <thead>\n",
       "    <tr style=\"text-align: right;\">\n",
       "      <th></th>\n",
       "      <th>Доля успешных</th>\n",
       "      <th>Количество пользователей</th>\n",
       "      <th>Успешных сессий</th>\n",
       "    </tr>\n",
       "    <tr>\n",
       "      <th>test_group</th>\n",
       "      <th></th>\n",
       "      <th></th>\n",
       "      <th></th>\n",
       "    </tr>\n",
       "  </thead>\n",
       "  <tbody>\n",
       "    <tr>\n",
       "      <th>A</th>\n",
       "      <td>0.3157 (31.57%)</td>\n",
       "      <td>15162</td>\n",
       "      <td>4787</td>\n",
       "    </tr>\n",
       "    <tr>\n",
       "      <th>B</th>\n",
       "      <td>0.3147 (31.47%)</td>\n",
       "      <td>15416</td>\n",
       "      <td>4851</td>\n",
       "    </tr>\n",
       "  </tbody>\n",
       "</table>\n",
       "</div>"
      ],
      "text/plain": [
       "              Доля успешных  Количество пользователей  Успешных сессий\n",
       "test_group                                                            \n",
       "A           0.3157 (31.57%)                     15162             4787\n",
       "B           0.3147 (31.47%)                     15416             4851"
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\n",
      "СРАВНЕНИЕ ГРУПП A И B:\n"
     ]
    },
    {
     "data": {
      "text/html": [
       "<div>\n",
       "<style scoped>\n",
       "    .dataframe tbody tr th:only-of-type {\n",
       "        vertical-align: middle;\n",
       "    }\n",
       "\n",
       "    .dataframe tbody tr th {\n",
       "        vertical-align: top;\n",
       "    }\n",
       "\n",
       "    .dataframe thead th {\n",
       "        text-align: right;\n",
       "    }\n",
       "</style>\n",
       "<table border=\"1\" class=\"dataframe\">\n",
       "  <thead>\n",
       "    <tr style=\"text-align: right;\">\n",
       "      <th></th>\n",
       "      <th>Показатель</th>\n",
       "      <th>Группа A</th>\n",
       "      <th>Группа B</th>\n",
       "      <th>Разница</th>\n",
       "    </tr>\n",
       "  </thead>\n",
       "  <tbody>\n",
       "    <tr>\n",
       "      <th>0</th>\n",
       "      <td>Доля успешных сессий</td>\n",
       "      <td>0.3157</td>\n",
       "      <td>0.3147</td>\n",
       "      <td>-0.0011</td>\n",
       "    </tr>\n",
       "    <tr>\n",
       "      <th>1</th>\n",
       "      <td>Количество пользователей</td>\n",
       "      <td>15,162</td>\n",
       "      <td>15,416</td>\n",
       "      <td>+254</td>\n",
       "    </tr>\n",
       "    <tr>\n",
       "      <th>2</th>\n",
       "      <td>Количество успешных сессий</td>\n",
       "      <td>4,787</td>\n",
       "      <td>4,851</td>\n",
       "      <td>+64</td>\n",
       "    </tr>\n",
       "    <tr>\n",
       "      <th>3</th>\n",
       "      <td>Доля успешных (%)</td>\n",
       "      <td>31.57%</td>\n",
       "      <td>31.47%</td>\n",
       "      <td>-0.11%</td>\n",
       "    </tr>\n",
       "  </tbody>\n",
       "</table>\n",
       "</div>"
      ],
      "text/plain": [
       "                   Показатель Группа A Группа B  Разница\n",
       "0        Доля успешных сессий   0.3157   0.3147  -0.0011\n",
       "1    Количество пользователей   15,162   15,416     +254\n",
       "2  Количество успешных сессий    4,787    4,851      +64\n",
       "3           Доля успешных (%)   31.57%   31.47%   -0.11%"
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\n",
      "ИТОГОВАЯ РАЗНИЦА МЕЖДУ ГРУППАМИ:\n"
     ]
    },
    {
     "data": {
      "text/html": [
       "<div>\n",
       "<style scoped>\n",
       "    .dataframe tbody tr th:only-of-type {\n",
       "        vertical-align: middle;\n",
       "    }\n",
       "\n",
       "    .dataframe tbody tr th {\n",
       "        vertical-align: top;\n",
       "    }\n",
       "\n",
       "    .dataframe thead th {\n",
       "        text-align: right;\n",
       "    }\n",
       "</style>\n",
       "<table border=\"1\" class=\"dataframe\">\n",
       "  <thead>\n",
       "    <tr style=\"text-align: right;\">\n",
       "      <th></th>\n",
       "      <th>Метрика</th>\n",
       "      <th>Значение</th>\n",
       "    </tr>\n",
       "  </thead>\n",
       "  <tbody>\n",
       "    <tr>\n",
       "      <th>0</th>\n",
       "      <td>Абсолютная разница (п.п.)</td>\n",
       "      <td>-0.11%</td>\n",
       "    </tr>\n",
       "    <tr>\n",
       "      <th>1</th>\n",
       "      <td>Относительное изменение (%)</td>\n",
       "      <td>-0.33%</td>\n",
       "    </tr>\n",
       "  </tbody>\n",
       "</table>\n",
       "</div>"
      ],
      "text/plain": [
       "                       Метрика Значение\n",
       "0    Абсолютная разница (п.п.)   -0.11%\n",
       "1  Относительное изменение (%)   -0.33%"
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "first_sessions_test = sessions_test[sessions_test['session_number'] == 1].copy()\n",
    "\n",
    "# Проверяем, что у каждого пользователя только одна первая сессия\n",
    "duplicates = first_sessions_test.duplicated('user_id').sum()\n",
    "if duplicates > 0:\n",
    "    print(f\"Найдено {duplicates} дубликатов. Оставляем только самую раннюю запись...\")\n",
    "    first_sessions_test = first_sessions_test.sort_values('session_start_ts').drop_duplicates('user_id')\n",
    "\n",
    "# Создаем DataFrame с информацией о первых сессиях\n",
    "first_sessions_info = pd.DataFrame({\n",
    "    'Показатель': ['Всего первых сессий', 'Уникальных пользователей'],\n",
    "    'Значение': [f\"{len(first_sessions_test):,}\", f\"{first_sessions_test['user_id'].nunique():,}\"]\n",
    "})\n",
    "print(\"\\nИНФОРМАЦИЯ О ПЕРВЫХ СЕССИЯХ:\")\n",
    "display(first_sessions_info)\n",
    "\n",
    "# Рассчитываем долю успешных сессий по группам\n",
    "good_session_by_group = first_sessions_test.groupby('test_group')['good_session'].agg(['mean', 'count', 'sum'])\n",
    "good_session_by_group.columns = ['Доля успешных', 'Количество пользователей', 'Успешных сессий']\n",
    "\n",
    "# Форматируем для отображения\n",
    "display_good_session = good_session_by_group.copy()\n",
    "display_good_session['Доля успешных'] = display_good_session['Доля успешных'].apply(lambda x: f'{x:.4f} ({x*100:.2f}%)')\n",
    "\n",
    "print(\"\\nРЕЗУЛЬТАТЫ ПО ГРУППАМ:\")\n",
    "display(display_good_session)\n",
    "\n",
    "# Рассчитываем разницу\n",
    "group_a_rate = good_session_by_group.loc['A', 'Доля успешных']\n",
    "group_b_rate = good_session_by_group.loc['B', 'Доля успешных']\n",
    "difference = group_b_rate - group_a_rate\n",
    "relative_diff = (difference / group_a_rate) * 100\n",
    "\n",
    "# Создаем DataFrame для сравнения групп\n",
    "comparison_df = pd.DataFrame({\n",
    "    'Показатель': [\n",
    "        'Доля успешных сессий', \n",
    "        'Количество пользователей', \n",
    "        'Количество успешных сессий',\n",
    "        'Доля успешных (%)'\n",
    "    ],\n",
    "    'Группа A': [\n",
    "        f'{group_a_rate:.4f}',\n",
    "        f\"{good_session_by_group.loc['A', 'Количество пользователей']:,}\",\n",
    "        f\"{good_session_by_group.loc['A', 'Успешных сессий']:,}\",\n",
    "        f'{group_a_rate*100:.2f}%'\n",
    "    ],\n",
    "    'Группа B': [\n",
    "        f'{group_b_rate:.4f}',\n",
    "        f\"{good_session_by_group.loc['B', 'Количество пользователей']:,}\",\n",
    "        f\"{good_session_by_group.loc['B', 'Успешных сессий']:,}\",\n",
    "        f'{group_b_rate*100:.2f}%'\n",
    "    ],\n",
    "    'Разница': [\n",
    "        f'{difference:+.4f}',\n",
    "        f\"{good_session_by_group.loc['B', 'Количество пользователей'] - good_session_by_group.loc['A', 'Количество пользователей']:+d}\",\n",
    "        f\"{good_session_by_group.loc['B', 'Успешных сессий'] - good_session_by_group.loc['A', 'Успешных сессий']:+d}\",\n",
    "        f'{difference*100:+.2f}%'\n",
    "    ]\n",
    "})\n",
    "\n",
    "print(\"\\nСРАВНЕНИЕ ГРУПП A И B:\")\n",
    "display(comparison_df)\n",
    "\n",
    "# Создаем DataFrame с разницей\n",
    "difference_df = pd.DataFrame({\n",
    "    'Метрика': ['Абсолютная разница (п.п.)', 'Относительное изменение (%)'],\n",
    "    'Значение': [f'{difference*100:+.2f}%', f'{relative_diff:+.2f}%']\n",
    "})\n",
    "\n",
    "print(\"\\nИТОГОВАЯ РАЗНИЦА МЕЖДУ ГРУППАМИ:\")\n",
    "display(difference_df)\n",
    "\n",
    "# Доверительные интервалы\n",
    "ci_a = proportion_confint(\n",
    "    good_session_by_group.loc['A', 'Успешных сессий'], \n",
    "    good_session_by_group.loc['A', 'Количество пользователей'], \n",
    "    alpha=0.05\n",
    ")\n",
    "ci_b = proportion_confint(\n",
    "    good_session_by_group.loc['B', 'Успешных сессий'], \n",
    "    good_session_by_group.loc['B', 'Количество пользователей'], \n",
    "    alpha=0.05\n",
    ")\n",
    "\n",
    "confidence_df = pd.DataFrame({\n",
    "    'Группа': ['A', 'B'],\n",
    "    'Доля успешных': [f'{group_a_rate*100:.2f}%', f'{group_b_rate*100:.2f}%'],\n",
    "    '95% ДИ нижняя': [f'{ci_a[0]*100:.2f}%', f'{ci_b[0]*100:.2f}%'],\n",
    "    '95% ДИ верхняя': [f'{ci_a[1]*100:.2f}%', f'{ci_b[1]*100:.2f}%']\n",
    "})\n"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {
    "id": "9fMFuja10eM4"
   },
   "source": [
    "#### 4.4. Насколько статистически значимо изменение ключевой метрики\n",
    "\n",
    "На предыдущем шаге вы убедились, что количество успешных сессий в тестовой выборке примерно на 1.1% выше, чем в контрольной, но делать выводы только на основе этого значения будет некорректно. Для принятия решения всегда необходимо отвечать на вопрос: является ли это изменение статистически значимым.\n",
    "\n",
    "- Используя статистический тест, рассчитайте, является ли изменение в метрике доли успешных сессий статистически значимым.\n",
    "\n",
    "- Выведите на экран полученное значение p-value и свои выводы о статистической значимости. Напомним, что уровень значимости в эксперименте был выбран на уровне 0.05."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 25,
   "metadata": {
    "id": "9z63yZMAG7i1"
   },
   "outputs": [
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "ИСХОДНЫЕ ДАННЫЕ:\n"
     ]
    },
    {
     "data": {
      "text/html": [
       "<div>\n",
       "<style scoped>\n",
       "    .dataframe tbody tr th:only-of-type {\n",
       "        vertical-align: middle;\n",
       "    }\n",
       "\n",
       "    .dataframe tbody tr th {\n",
       "        vertical-align: top;\n",
       "    }\n",
       "\n",
       "    .dataframe thead th {\n",
       "        text-align: right;\n",
       "    }\n",
       "</style>\n",
       "<table border=\"1\" class=\"dataframe\">\n",
       "  <thead>\n",
       "    <tr style=\"text-align: right;\">\n",
       "      <th></th>\n",
       "      <th>Группа</th>\n",
       "      <th>Успешных сессий</th>\n",
       "      <th>Всего пользователей</th>\n",
       "      <th>Доля успешных</th>\n",
       "    </tr>\n",
       "  </thead>\n",
       "  <tbody>\n",
       "    <tr>\n",
       "      <th>0</th>\n",
       "      <td>A (контроль)</td>\n",
       "      <td>4,787</td>\n",
       "      <td>15,162</td>\n",
       "      <td>0.3157 (31.57%)</td>\n",
       "    </tr>\n",
       "    <tr>\n",
       "      <th>1</th>\n",
       "      <td>B (тест)</td>\n",
       "      <td>4,851</td>\n",
       "      <td>15,416</td>\n",
       "      <td>0.3147 (31.47%)</td>\n",
       "    </tr>\n",
       "  </tbody>\n",
       "</table>\n",
       "</div>"
      ],
      "text/plain": [
       "         Группа Успешных сессий Всего пользователей    Доля успешных\n",
       "0  A (контроль)           4,787              15,162  0.3157 (31.57%)\n",
       "1      B (тест)           4,851              15,416  0.3147 (31.47%)"
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\n",
      "Абсолютная разница: -0.11%\n",
      "Относительное изменение: -0.33%\n",
      "\n",
      "======================================================================\n",
      "Проверка, что B > A \n",
      "РЕЗУЛЬТАТ ТЕСТА (B > A):\n"
     ]
    },
    {
     "data": {
      "text/html": [
       "<div>\n",
       "<style scoped>\n",
       "    .dataframe tbody tr th:only-of-type {\n",
       "        vertical-align: middle;\n",
       "    }\n",
       "\n",
       "    .dataframe tbody tr th {\n",
       "        vertical-align: top;\n",
       "    }\n",
       "\n",
       "    .dataframe thead th {\n",
       "        text-align: right;\n",
       "    }\n",
       "</style>\n",
       "<table border=\"1\" class=\"dataframe\">\n",
       "  <thead>\n",
       "    <tr style=\"text-align: right;\">\n",
       "      <th></th>\n",
       "      <th>Параметр</th>\n",
       "      <th>Значение</th>\n",
       "    </tr>\n",
       "  </thead>\n",
       "  <tbody>\n",
       "    <tr>\n",
       "      <th>0</th>\n",
       "      <td>P-value</td>\n",
       "      <td>0.578352</td>\n",
       "    </tr>\n",
       "    <tr>\n",
       "      <th>1</th>\n",
       "      <td>Z-statistic</td>\n",
       "      <td>-0.1977</td>\n",
       "    </tr>\n",
       "    <tr>\n",
       "      <th>2</th>\n",
       "      <td>Гипотеза</td>\n",
       "      <td>B &gt; A</td>\n",
       "    </tr>\n",
       "  </tbody>\n",
       "</table>\n",
       "</div>"
      ],
      "text/plain": [
       "      Параметр  Значение\n",
       "0      P-value  0.578352\n",
       "1  Z-statistic   -0.1977\n",
       "2     Гипотеза     B > A"
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "first_sessions_test = sessions_test[sessions_test['session_number'] == 1].copy()\n",
    "first_sessions_test = first_sessions_test.sort_values('session_start_ts').drop_duplicates('user_id')\n",
    "\n",
    "success_a = first_sessions_test[first_sessions_test['test_group'] == 'A']['good_session'].sum()\n",
    "success_b = first_sessions_test[first_sessions_test['test_group'] == 'B']['good_session'].sum()\n",
    "nobs_a = first_sessions_test[first_sessions_test['test_group'] == 'A']['good_session'].count()\n",
    "nobs_b = first_sessions_test[first_sessions_test['test_group'] == 'B']['good_session'].count()\n",
    "\n",
    "# Рассчитываем доли\n",
    "p_a = success_a / nobs_a\n",
    "p_b = success_b / nobs_b\n",
    "abs_diff = p_b - p_a\n",
    "rel_diff = (abs_diff / p_a) * 100\n",
    "\n",
    "# Создаем DataFrame с исходными данными\n",
    "input_data = pd.DataFrame({\n",
    "    'Группа': ['A (контроль)', 'B (тест)'],\n",
    "    'Успешных сессий': [f\"{success_a:,}\", f\"{success_b:,}\"],\n",
    "    'Всего пользователей': [f\"{nobs_a:,}\", f\"{nobs_b:,}\"],\n",
    "    'Доля успешных': [f\"{p_a:.4f} ({p_a*100:.2f}%)\", f\"{p_b:.4f} ({p_b*100:.2f}%)\"]\n",
    "})\n",
    "\n",
    "print(\"ИСХОДНЫЕ ДАННЫЕ:\")\n",
    "display(input_data)\n",
    "\n",
    "print(f\"\\nАбсолютная разница: {abs_diff*100:+.2f}%\")\n",
    "print(f\"Относительное изменение: {rel_diff:+.2f}%\")\n",
    "\n",
    "print(\"\\n\" + \"=\"*70)\n",
    "print(\"Проверка, что B > A \")\n",
    "\n",
    "# Меняем порядок: сначала B, потом A\n",
    "counts_correct = [success_b, success_a]\n",
    "nobs_correct = [nobs_b, nobs_a]\n",
    "\n",
    "z_stat_correct, p_value_correct = proportions_ztest(\n",
    "    counts_correct, \n",
    "    nobs_correct, \n",
    "    alternative='larger'  # проверяем, что первая группа (B) больше второй (A)\n",
    ")\n",
    "\n",
    "# Создаем DataFrame для результата\n",
    "result1_df = pd.DataFrame({\n",
    "    'Параметр': ['P-value', 'Z-statistic', 'Гипотеза'],\n",
    "    'Значение': [f\"{p_value_correct:.6f}\", f\"{z_stat_correct:.4f}\", 'B > A']\n",
    "})\n",
    "\n",
    "print(\"РЕЗУЛЬТАТ ТЕСТА (B > A):\")\n",
    "display(result1_df)"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {
    "id": "GnJrkY9Q63zS"
   },
   "source": [
    "#### 4.5. Вывод по результатам A/B-эксперимента\n",
    "\n",
    "На основе проведённого анализа результатов теста сформулируйте и запишите свои выводы для команды разработки приложения. В выводе обязательно укажите:\n",
    "\n",
    "- Характеристики проведённого эксперимента, количество задействованных пользователей и длительность эксперимента.\n",
    "\n",
    "- Повлияло ли внедрение нового алгоритма рекомендаций на рост ключевой метрики и как.\n",
    "\n",
    "- Каким получилось значение p-value для оценки статистической значимости выявленного эффекта.\n",
    "\n",
    "- Стоит ли внедрять нововведение в приложение."
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {
    "id": "EarRZ-cVHD3I"
   },
   "source": [
    "## 4.5. Вывод по результатам A/B-эксперимента\n",
    "\n",
    "### Характеристики эксперимента\n",
    "- **Период проведения:** с 2025-10-14 по 2025-11-02 (20 дней)\n",
    "- **Количество пользователей в группе A (контроль):** 15 162 пользователя\n",
    "- **Количество пользователей в группе B (тест):** 15 416 пользователей\n",
    "- **Запланированный размер выборки:** 39 034 пользователя на группу (фактический размер меньше необходимого)\n",
    "- **Целевая метрика:** доля успешных первых сессий (просмотр 4+ страниц)\n",
    "\n",
    "### Влияние на ключевую метрику\n",
    "- **Группа A (старый алгоритм):** доля успешных сессий = 31.57%\n",
    "- **Группа B (новый алгоритм):** доля успешных сессий = 31.47%\n",
    "- **Абсолютная разница:** -0.11 процентных пункта\n",
    "- **Относительное изменение:** -0.33%\n",
    "\n",
    "### Статистическая значимость\n",
    "- **P-value (для проверки, что B > A):** 0.578352\n",
    "- **Уровень значимости (α):** 0.05\n",
    "- Предварительный анализ показывает, что новый алгоритм не дал ожидаемого улучшения\n",
    "\n",
    "### Выводы и рекомендации\n",
    "\n",
    "1. **Результат эксперимента:**\n",
    "   Новый алгоритм рекомендаций НЕ показал улучшения ключевой метрики. Наблюдается незначительное снижение доли успешных первых сессий на 0.11 процентных пункта (относительное снижение на 0.33%).\n",
    "\n",
    "2. **Сравнение с запланированным MDE:**\n",
    "   - Запланированный MDE: +0.93% (3% относительных от базового значения 31.06%)\n",
    "   - Фактическое изменение: -0.11%\n",
    "   - Фактический эффект значительно ниже минимального детектируемого и имеет отрицательный знак\n",
    "\n",
    "3. **Достаточность выборки:**\n",
    "   - Фактический размер выборки (≈15 тыс. на группу) меньше необходимого (39 тыс. на группу)\n",
    "   - Тест мог не обнаружить малые эффекты из-за недостаточной мощности\n",
    "\n",
    "4. **Рекомендация:**\n",
    "   - **Новый алгоритм НЕ рекомендуется к внедрению** в текущем виде\n",
    "   - Продолжить использовать текущий алгоритм рекомендаций\n",
    "   - Проанализировать причины ухудшения метрики\n",
    "   - Рассмотреть возможность доработки алгоритма и проведения повторного теста с увеличенной выборкой\n",
    "\n",
    "5. **Дополнительные рекомендации:**\n",
    "   - Увеличить длительность теста для достижения необходимого размера выборки\n",
    "   - Провести анализ влияния нового алгоритма на другие метрики (удержание, глубина просмотра)\n",
    "   - Исследовать, почему алгоритм показал отрицательный эффект"
   ]
  }
 ],
 "metadata": {
  "ExecuteTimeLog": [
   {
    "duration": 2994,
    "start_time": "2026-03-10T13:28:35.887Z"
   },
   {
    "duration": 1219,
    "start_time": "2026-03-10T13:34:29.966Z"
   },
   {
    "duration": 604,
    "start_time": "2026-03-10T13:34:31.388Z"
   },
   {
    "duration": 1086,
    "start_time": "2026-03-10T13:34:37.441Z"
   },
   {
    "duration": 1591,
    "start_time": "2026-03-10T13:34:45.625Z"
   },
   {
    "duration": 1592,
    "start_time": "2026-03-10T13:34:52.140Z"
   },
   {
    "duration": 23,
    "start_time": "2026-03-10T13:34:58.717Z"
   },
   {
    "duration": 150,
    "start_time": "2026-03-10T13:35:04.038Z"
   },
   {
    "duration": 190,
    "start_time": "2026-03-10T13:35:17.763Z"
   },
   {
    "duration": 8,
    "start_time": "2026-03-10T13:35:22.057Z"
   },
   {
    "duration": 311,
    "start_time": "2026-03-10T13:35:26.102Z"
   },
   {
    "duration": 359,
    "start_time": "2026-03-10T13:35:40.044Z"
   },
   {
    "duration": 321,
    "start_time": "2026-03-10T20:33:35.360Z"
   },
   {
    "duration": 291,
    "start_time": "2026-03-10T20:33:49.642Z"
   },
   {
    "duration": 385,
    "start_time": "2026-03-10T20:35:09.875Z"
   },
   {
    "duration": 49,
    "start_time": "2026-03-10T20:35:15.837Z"
   },
   {
    "duration": 32,
    "start_time": "2026-03-10T20:37:40.428Z"
   },
   {
    "duration": 417,
    "start_time": "2026-03-13T16:03:37.834Z"
   },
   {
    "duration": 3,
    "start_time": "2026-03-13T16:03:38.672Z"
   },
   {
    "duration": 457,
    "start_time": "2026-03-13T16:03:39.282Z"
   },
   {
    "duration": 3,
    "start_time": "2026-03-13T16:03:40.557Z"
   },
   {
    "duration": 533,
    "start_time": "2026-03-13T16:03:41.340Z"
   },
   {
    "duration": 9,
    "start_time": "2026-03-13T16:03:42.341Z"
   },
   {
    "duration": 4,
    "start_time": "2026-03-13T16:03:43.179Z"
   },
   {
    "duration": 3,
    "start_time": "2026-03-13T16:04:39.890Z"
   },
   {
    "duration": 1124,
    "start_time": "2026-03-13T16:05:42.798Z"
   },
   {
    "duration": 16,
    "start_time": "2026-03-13T16:06:00.348Z"
   },
   {
    "duration": 581,
    "start_time": "2026-03-13T16:10:00.436Z"
   },
   {
    "duration": 1123,
    "start_time": "2026-03-13T16:12:22.279Z"
   },
   {
    "duration": 1446,
    "start_time": "2026-03-13T16:12:42.488Z"
   },
   {
    "duration": 1497,
    "start_time": "2026-03-13T16:12:53.228Z"
   },
   {
    "duration": 76,
    "start_time": "2026-03-13T16:14:58.114Z"
   },
   {
    "duration": 152,
    "start_time": "2026-03-13T16:17:31.970Z"
   },
   {
    "duration": 142,
    "start_time": "2026-03-13T16:18:46.738Z"
   },
   {
    "duration": 126,
    "start_time": "2026-03-13T16:19:14.559Z"
   },
   {
    "duration": 772,
    "start_time": "2026-03-13T16:20:55.342Z"
   },
   {
    "duration": 131,
    "start_time": "2026-03-13T16:21:10.668Z"
   },
   {
    "duration": 134,
    "start_time": "2026-03-13T16:21:46.082Z"
   },
   {
    "duration": 604,
    "start_time": "2026-03-13T16:23:13.345Z"
   },
   {
    "duration": 395,
    "start_time": "2026-03-13T16:24:22.164Z"
   },
   {
    "duration": 52,
    "start_time": "2026-03-13T16:36:01.157Z"
   },
   {
    "duration": 1471,
    "start_time": "2026-03-13T16:36:26.868Z"
   },
   {
    "duration": 5,
    "start_time": "2026-03-13T16:36:28.341Z"
   },
   {
    "duration": 1298,
    "start_time": "2026-03-13T16:36:28.347Z"
   },
   {
    "duration": 16,
    "start_time": "2026-03-13T16:36:29.647Z"
   },
   {
    "duration": 676,
    "start_time": "2026-03-13T16:36:31.038Z"
   },
   {
    "duration": 1196,
    "start_time": "2026-03-13T16:36:39.937Z"
   },
   {
    "duration": 1559,
    "start_time": "2026-03-13T16:36:42.766Z"
   },
   {
    "duration": 1568,
    "start_time": "2026-03-13T16:36:46.582Z"
   },
   {
    "duration": 83,
    "start_time": "2026-03-13T16:36:50.847Z"
   },
   {
    "duration": 157,
    "start_time": "2026-03-13T16:36:56.281Z"
   },
   {
    "duration": 373,
    "start_time": "2026-03-13T16:37:00.052Z"
   },
   {
    "duration": 9,
    "start_time": "2026-03-13T16:37:01.885Z"
   },
   {
    "duration": 602,
    "start_time": "2026-03-13T16:37:04.832Z"
   },
   {
    "duration": 322,
    "start_time": "2026-03-13T16:37:10.144Z"
   },
   {
    "duration": 740,
    "start_time": "2026-03-13T16:37:18.428Z"
   },
   {
    "duration": 282,
    "start_time": "2026-03-13T16:38:16.582Z"
   },
   {
    "duration": 292,
    "start_time": "2026-03-13T16:38:16.866Z"
   },
   {
    "duration": 88,
    "start_time": "2026-03-13T16:38:56.569Z"
   },
   {
    "duration": 855,
    "start_time": "2026-03-13T16:40:02.349Z"
   },
   {
    "duration": 336,
    "start_time": "2026-03-13T16:41:45.916Z"
   },
   {
    "duration": 76,
    "start_time": "2026-03-13T16:43:32.556Z"
   },
   {
    "duration": 66,
    "start_time": "2026-03-13T16:44:07.989Z"
   },
   {
    "duration": 4,
    "start_time": "2026-03-13T16:47:46.286Z"
   },
   {
    "duration": 4,
    "start_time": "2026-03-13T16:47:46.503Z"
   },
   {
    "duration": 1149,
    "start_time": "2026-03-13T16:47:46.702Z"
   },
   {
    "duration": 12,
    "start_time": "2026-03-13T16:47:47.852Z"
   },
   {
    "duration": 578,
    "start_time": "2026-03-13T16:47:48.578Z"
   },
   {
    "duration": 931,
    "start_time": "2026-03-13T16:47:49.493Z"
   },
   {
    "duration": 1526,
    "start_time": "2026-03-13T16:47:51.474Z"
   },
   {
    "duration": 1607,
    "start_time": "2026-03-13T16:47:53.002Z"
   },
   {
    "duration": 85,
    "start_time": "2026-03-13T16:47:54.612Z"
   },
   {
    "duration": 155,
    "start_time": "2026-03-13T16:47:54.699Z"
   },
   {
    "duration": 140,
    "start_time": "2026-03-13T16:47:58.085Z"
   },
   {
    "duration": 9,
    "start_time": "2026-03-13T16:48:00.196Z"
   },
   {
    "duration": 527,
    "start_time": "2026-03-13T16:48:01.008Z"
   },
   {
    "duration": 359,
    "start_time": "2026-03-13T16:48:02.958Z"
   },
   {
    "duration": 301,
    "start_time": "2026-03-13T16:48:05.882Z"
   },
   {
    "duration": 169,
    "start_time": "2026-03-13T16:48:07.690Z"
   },
   {
    "duration": 31,
    "start_time": "2026-03-13T16:48:11.846Z"
   },
   {
    "duration": 32,
    "start_time": "2026-03-13T16:49:03.472Z"
   },
   {
    "duration": 54,
    "start_time": "2026-03-14T08:25:42.977Z"
   },
   {
    "duration": 1323,
    "start_time": "2026-03-14T08:25:57.239Z"
   },
   {
    "duration": 4,
    "start_time": "2026-03-14T08:25:58.564Z"
   },
   {
    "duration": 1199,
    "start_time": "2026-03-14T08:25:58.570Z"
   },
   {
    "duration": 15,
    "start_time": "2026-03-14T08:25:59.771Z"
   },
   {
    "duration": 687,
    "start_time": "2026-03-14T08:26:00.229Z"
   },
   {
    "duration": 1199,
    "start_time": "2026-03-14T08:26:00.918Z"
   },
   {
    "duration": 1677,
    "start_time": "2026-03-14T08:26:02.119Z"
   },
   {
    "duration": 1666,
    "start_time": "2026-03-14T08:26:03.798Z"
   },
   {
    "duration": 94,
    "start_time": "2026-03-14T08:26:05.467Z"
   },
   {
    "duration": 170,
    "start_time": "2026-03-14T08:26:05.563Z"
   },
   {
    "duration": 151,
    "start_time": "2026-03-14T08:26:05.734Z"
   },
   {
    "duration": 9,
    "start_time": "2026-03-14T08:26:05.888Z"
   },
   {
    "duration": 589,
    "start_time": "2026-03-14T08:26:06.837Z"
   },
   {
    "duration": 421,
    "start_time": "2026-03-14T08:26:09.825Z"
   },
   {
    "duration": 317,
    "start_time": "2026-03-14T08:26:13.999Z"
   },
   {
    "duration": 73,
    "start_time": "2026-03-14T08:26:16.842Z"
   },
   {
    "duration": 97,
    "start_time": "2026-03-14T08:26:20.377Z"
   },
   {
    "duration": 98,
    "start_time": "2026-03-14T08:29:55.047Z"
   },
   {
    "duration": 101,
    "start_time": "2026-03-14T08:30:40.600Z"
   },
   {
    "duration": 100,
    "start_time": "2026-03-14T08:33:50.396Z"
   },
   {
    "duration": 108,
    "start_time": "2026-03-14T08:36:50.209Z"
   },
   {
    "duration": 100,
    "start_time": "2026-03-14T08:37:37.101Z"
   },
   {
    "duration": 102,
    "start_time": "2026-03-14T08:37:45.667Z"
   },
   {
    "duration": 102,
    "start_time": "2026-03-14T08:38:20.774Z"
   }
  ],
  "colab": {
   "collapsed_sections": [
    "5MNIv_8CRFlG"
   ],
   "provenance": []
  },
  "kernelspec": {
   "display_name": "Python 3 (ipykernel)",
   "language": "python",
   "name": "python3"
  },
  "language_info": {
   "codemirror_mode": {
    "name": "ipython",
    "version": 3
   },
   "file_extension": ".py",
   "mimetype": "text/x-python",
   "name": "python",
   "nbconvert_exporter": "python",
   "pygments_lexer": "ipython3",
   "version": "3.9.5"
  },
  "toc": {
   "base_numbering": 1,
   "nav_menu": {},
   "number_sections": true,
   "sideBar": true,
   "skip_h1_title": true,
   "title_cell": "Table of Contents",
   "title_sidebar": "Contents",
   "toc_cell": false,
   "toc_position": {},
   "toc_section_display": true,
   "toc_window_display": false
  }
 },
 "nbformat": 4,
 "nbformat_minor": 1
}