# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: pzau <marvin@42.fr>                        +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2025/11/21 10:16:54 by pzau              #+#    #+#              #
#    Updated: 2025/11/21 10:16:55 by pzau             ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

all:
	mkdir -p ~/data/wordpress ~/data/mariadb
	docker compose build
	docker compose up -d
	clear
	echo "All containers builded"

clean:
	docker compose down

down:
	docker compose down --remove-orphans --volumes

re: down all

.PHONY: all clean down re
